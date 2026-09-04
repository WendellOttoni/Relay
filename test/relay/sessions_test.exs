defmodule Relay.SessionsTest do
  use ExUnit.Case, async: false

  setup do
    previous_ttl = Application.get_env(:relay, :session_ttl_seconds)
    previous_limiter = Application.get_env(:relay, :session_rate_limiter)
    previous_chat_enabled = Application.get_env(:relay, :chat_enabled)

    start_supervised!({Relay.Sessions.RateLimiter, name: Relay.SessionsTestLimiter, limit: 100})
    Application.put_env(:relay, :session_ttl_seconds, 300)
    Application.put_env(:relay, :session_rate_limiter, Relay.SessionsTestLimiter)
    Application.put_env(:relay, :chat_enabled, true)

    on_exit(fn ->
      restore_env(:session_ttl_seconds, previous_ttl)
      restore_env(:session_rate_limiter, previous_limiter)
      restore_env(:chat_enabled, previous_chat_enabled)
    end)
  end

  test "issues a signed, short-lived token and verifies its public claims" do
    before_creation = DateTime.utc_now()
    assert {:ok, session} = Relay.Sessions.create_session(%{})
    assert byte_size(session.session_id) >= 20
    assert DateTime.diff(session.expires_at, before_creation, :second) in 299..300
    assert {:ok, verified} = Relay.Sessions.verify_socket_token(session.socket_token)
    assert verified.session_id == session.session_id
    assert verified.expires_at == session.expires_at
  end

  test "uses a fresh cryptographically random id for every session" do
    assert {:ok, first} = Relay.Sessions.create_session(%{})
    assert {:ok, second} = Relay.Sessions.create_session(%{})
    refute first.session_id == second.session_id
  end

  test "does not issue credentials while chat is disabled" do
    Application.put_env(:relay, :chat_enabled, false)
    assert {:error, :chat_disabled} = Relay.Sessions.create_session(%{})
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
    assert {:ok, _session} = Relay.Sessions.create_session(%{network_key: "client-a"})
    assert {:error, :rate_limited} = Relay.Sessions.create_session(%{network_key: "client-a"})
    assert {:ok, _session} = Relay.Sessions.create_session(%{network_key: "client-b"})
  end

  defp restore_env(key, nil), do: Application.delete_env(:relay, key)
  defp restore_env(key, value), do: Application.put_env(:relay, key, value)

  defp unique_limiter_name(prefix) do
    Module.concat(__MODULE__, String.to_atom("#{prefix}#{System.unique_integer([:positive])}"))
  end
end
