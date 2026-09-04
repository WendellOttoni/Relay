defmodule RelayWeb.SessionControllerTest do
  use RelayWeb.ConnCase, async: false

  setup do
    previous_limiter = Application.get_env(:relay, :session_rate_limiter)
    previous_chat_enabled = Application.get_env(:relay, :chat_enabled)

    start_supervised!(
      {Relay.Sessions.RateLimiter, name: Relay.SessionControllerTestLimiter, limit: 100}
    )

    Application.put_env(:relay, :session_rate_limiter, Relay.SessionControllerTestLimiter)
    Application.put_env(:relay, :chat_enabled, true)

    on_exit(fn ->
      restore_env(:session_rate_limiter, previous_limiter)
      restore_env(:chat_enabled, previous_chat_enabled)
    end)
  end

  test "creates a session with the documented JSON shape", %{conn: conn} do
    conn = RelayWeb.SessionController.create(conn, %{})

    assert %{"sessionId" => session_id, "socketToken" => socket_token, "expiresAt" => expires_at} =
             json_response(conn, 201)

    assert {:ok, %{session_id: ^session_id}} = Relay.Sessions.verify_socket_token(socket_token)
    assert {:ok, _date_time, 0} = DateTime.from_iso8601(expires_at)
  end

  test "does not issue sessions while the emergency chat switch is off", %{conn: conn} do
    Application.put_env(:relay, :chat_enabled, false)
    conn = RelayWeb.SessionController.create(conn, %{})
    assert %{"error" => %{"code" => "chat_unavailable"}} = json_response(conn, 503)
  end

  test "returns too many requests after the per-network limit", %{conn: conn} do
    limiter_name = unique_limiter_name("StrictControllerLimiter")

    start_supervised!(%{
      id: limiter_name,
      start: {Relay.Sessions.RateLimiter, :start_link, [[name: limiter_name, limit: 1]]}
    })

    Application.put_env(:relay, :session_rate_limiter, limiter_name)
    first = RelayWeb.SessionController.create(conn, %{})
    assert json_response(first, 201)
    second = RelayWeb.SessionController.create(conn, %{})
    assert %{"error" => %{"code" => "rate_limit_exceeded"}} = json_response(second, 429)
  end

  defp restore_env(key, nil), do: Application.delete_env(:relay, key)
  defp restore_env(key, value), do: Application.put_env(:relay, key, value)

  defp unique_limiter_name(prefix) do
    Module.concat(__MODULE__, String.to_atom("#{prefix}#{System.unique_integer([:positive])}"))
  end
end
