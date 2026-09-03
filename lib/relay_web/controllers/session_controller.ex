defmodule RelayWeb.SessionController do
  use RelayWeb, :controller

  def create(conn, params) do
    params = Map.put(params, :remote_ip, conn.remote_ip)

    case Relay.Sessions.create_session(params) do
      {:ok, session} ->
        conn
        |> put_status(:created)
        |> json(%{
          sessionId: session.session_id,
          socketToken: session.socket_token,
          expiresAt: DateTime.to_iso8601(session.expires_at)
        })

      {:error, :missing_challenge} ->
        RelayWeb.ErrorResponse.send(
          conn,
          400,
          "invalid_request",
          "O desafio antiabuso é obrigatório."
        )

      {:error, :chat_disabled} ->
        RelayWeb.ErrorResponse.send(
          conn,
          503,
          "chat_unavailable",
          "O chat está temporariamente indisponível."
        )

      {:error, :validator_unavailable} ->
        RelayWeb.ErrorResponse.send(
          conn,
          503,
          "sessions_unavailable",
          "A criação de sessões está temporariamente indisponível."
        )

      {:error, :limiter_unavailable} ->
        RelayWeb.ErrorResponse.send(
          conn,
          503,
          "sessions_unavailable",
          "A criação de sessões está temporariamente indisponível."
        )

      {:error, :rate_limited} ->
        RelayWeb.ErrorResponse.send(
          conn,
          429,
          "rate_limit_exceeded",
          "Limite temporário atingido."
        )

      {:error, _reason} ->
        RelayWeb.ErrorResponse.send(
          conn,
          403,
          "challenge_rejected",
          "Desafio antiabuso recusado."
        )
    end
  end
end
