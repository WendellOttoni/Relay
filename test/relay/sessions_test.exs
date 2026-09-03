defmodule Relay.SessionsTest do
  use ExUnit.Case, async: false

  setup do
    previous_validator = Application.get_env(:relay, :turnstile_validator)
    previous_tokens = Application.get_env(:relay, :turnstile_fake_tokens)
    previous_ttl = Application.get_env(:relay, :session_ttl_seconds)
    previous_limiter = Application.get_env(:relay, :session_rate_limiter)

    start_supervised!({Relay.Sessions.RateLimiter, name: Relay.SessionsTestLimiter, limit: 100})

    Application.put_env(:relay, :turnstile_validator, Relay.Sessions.Turnstile.Fake)
    Application.put_env(:relay, :turnstile_fake_tokens, ["accepted-token"])
    Application.put_env(:relay, :session_ttl_seconds, 300)
    Application.put_env(:relay, :session_rate_limiter, Relay.SessionsTestLimiter)

    on_exit(fn ->
      restore_env(:turnstile_validator, previous_validator)
      restore_env(:turnstile_fake_tokens, previous_tokens)
      restore_env(:session_ttl_seconds, previous_ttl)
      restore_env(:session_rate_limiter, previous_limiter)
    end)
  end

  test "issues a signed, short-lived token and verifies its public claims" do
    before_creation = DateTime.utc_now()

    assert {:ok, session} = Relay.Sessions.create_session(%{"turnstileToken" => "accepted-token"})
    assert byte_size(session.session_id) >= 20

    assert DateTime.compare(session.expires_at, DateTime.add(before_creation, 300, :second)) in [
             :eq,
             :gt
           ]

    assert {:ok, verified} = Relay.Sessions.verify_socket_token(session.socket_token)
    assert verified.session_id == session.session_id
    assert verified.expires_at == session.expires_at
  end

  test "uses a fresh cryptographically random id for every session" do
    assert {:ok, first} = Relay.Sessions.create_session(%{turnstile_token: "accepted-token"})
    assert {:ok, second} = Relay.Sessions.create_session(%{turnstile_token: "accepted-token"})
    refute first.session_id == second.session_id
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

  test "rejects forged tokens" do
    assert {:error, :invalid} = Relay.Sessions.verify_socket_token("not-a-signed-token")
  end

  test "limits repeated creation attempts per network key" do
    start_supervised!({Relay.Sessions.RateLimiter, name: Relay.StrictSessionLimiter, limit: 1})
    Application.put_env(:relay, :session_rate_limiter, Relay.StrictSessionLimiter)

    attrs = %{turnstile_token: "accepted-token", network_key: "client-a"}
    assert {:ok, _session} = Relay.Sessions.create_session(attrs)
    assert {:error, :rate_limited} = Relay.Sessions.create_session(attrs)

    assert {:ok, _session} =
             Relay.Sessions.create_session(%{attrs | network_key: "client-b"})
  end

  defp restore_env(key, nil), do: Application.delete_env(:relay, key)
  defp restore_env(key, value), do: Application.put_env(:relay, key, value)
end
