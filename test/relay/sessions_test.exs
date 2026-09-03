defmodule Relay.SessionsTest do
  use ExUnit.Case, async: false

  setup do
    previous_validator = Application.get_env(:relay, :turnstile_validator)
    previous_tokens = Application.get_env(:relay, :turnstile_fake_tokens)
    previous_ttl = Application.get_env(:relay, :session_ttl_seconds)
    previous_limiter = Application.get_env(:relay, :session_rate_limiter)
    previous_token_store = Application.get_env(:relay, :turnstile_token_store)
    previous_chat_enabled = Application.get_env(:relay, :chat_enabled)

    start_supervised!({Relay.Sessions.RateLimiter, name: Relay.SessionsTestLimiter, limit: 100})
    start_supervised!({Relay.Sessions.Turnstile.TokenStore, name: Relay.SessionsTestTokenStore})

    Application.put_env(:relay, :turnstile_validator, Relay.Sessions.Turnstile.Fake)
    Application.put_env(:relay, :turnstile_fake_tokens, ["accepted-token", "accepted-token-2"])
    Application.put_env(:relay, :session_ttl_seconds, 300)
    Application.put_env(:relay, :session_rate_limiter, Relay.SessionsTestLimiter)
    Application.put_env(:relay, :turnstile_token_store, Relay.SessionsTestTokenStore)
    Application.put_env(:relay, :chat_enabled, true)

    on_exit(fn ->
      restore_env(:turnstile_validator, previous_validator)
      restore_env(:turnstile_fake_tokens, previous_tokens)
      restore_env(:session_ttl_seconds, previous_ttl)
      restore_env(:session_rate_limiter, previous_limiter)
      restore_env(:turnstile_token_store, previous_token_store)
      restore_env(:chat_enabled, previous_chat_enabled)
    end)
  end

  test "issues a signed, short-lived token and verifies its public claims" do
    before_creation = DateTime.utc_now()

    assert {:ok, session} = Relay.Sessions.create_session(%{"turnstileToken" => "accepted-token"})
    assert byte_size(session.session_id) >= 20

    # The public timestamp is second-precision, so it may be fractionally
    # before the wall-clock instant captured above.
    assert DateTime.diff(session.expires_at, before_creation, :second) in 299..300

    assert {:ok, verified} = Relay.Sessions.verify_socket_token(session.socket_token)
    assert verified.session_id == session.session_id
    assert verified.expires_at == session.expires_at
  end

  test "uses a fresh cryptographically random id for every session" do
    assert {:ok, first} = Relay.Sessions.create_session(%{turnstile_token: "accepted-token"})

    assert {:ok, second} =
             Relay.Sessions.create_session(%{turnstile_token: "accepted-token-2"})

    refute first.session_id == second.session_id
  end

  test "allows a successful challenge token to create only one session" do
    attrs = %{turnstile_token: "accepted-token", network_key: "another-client"}

    assert {:ok, _session} = Relay.Sessions.create_session(attrs)
    assert {:error, :challenge_replayed} = Relay.Sessions.create_session(attrs)
  end

  test "atomically rejects concurrent attempts to reuse a challenge token" do
    results =
      1..10
      |> Task.async_stream(
        fn _ ->
          Relay.Sessions.Turnstile.TokenStore.consume(
            "accepted-token",
            Relay.SessionsTestTokenStore
          )
        end,
        max_concurrency: 10,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &(&1 == :ok)) == 1
    assert Enum.count(results, &(&1 == {:error, :challenge_replayed})) == 9
  end

  test "rejects missing and refused challenges" do
    assert {:error, :missing_challenge} = Relay.Sessions.create_session(%{})

    assert {:error, :invalid_challenge} =
             Relay.Sessions.create_session(%{turnstile_token: "refused-token"})
  end

  test "fails closed when no validator is configured" do
    Application.delete_env(:relay, :turnstile_validator)

    assert {:error, :validator_unavailable} =
             Relay.Sessions.create_session(%{turnstile_token: "anything"})
  end

  test "does not issue credentials while chat is disabled" do
    Application.put_env(:relay, :chat_enabled, false)

    assert {:error, :chat_disabled} =
             Relay.Sessions.create_session(%{turnstile_token: "accepted-token"})
  end

  test "rejects forged tokens" do
    assert {:error, :invalid} = Relay.Sessions.verify_socket_token("not-a-signed-token")
  end

  test "limits repeated creation attempts per network key" do
    limiter_name = unique_limiter_name("StrictSessionLimiter")

    start_supervised!(%{
      id: limiter_name,
      start: {Relay.Sessions.RateLimiter, :start_link, [[name: limiter_name, limit: 1]]}
    })

    Application.put_env(:relay, :session_rate_limiter, limiter_name)

    attrs = %{turnstile_token: "accepted-token", network_key: "client-a"}
    assert {:ok, _session} = Relay.Sessions.create_session(attrs)
    assert {:error, :rate_limited} = Relay.Sessions.create_session(attrs)

    assert {:ok, _session} =
             Relay.Sessions.create_session(%{
               turnstile_token: "accepted-token-2",
               network_key: "client-b"
             })
  end

  defp restore_env(key, nil), do: Application.delete_env(:relay, key)
  defp restore_env(key, value), do: Application.put_env(:relay, key, value)

  defp unique_limiter_name(prefix) do
    Module.concat(__MODULE__, String.to_atom("#{prefix}#{System.unique_integer([:positive])}"))
  end
end
