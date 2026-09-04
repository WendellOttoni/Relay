defmodule RelayWeb.LeadController do
  use RelayWeb, :controller

  def create(conn, params) do
    with {:ok, token} <- bearer_token(conn),
         {:ok, %{session_id: session_id}} <- Relay.Sessions.verify_socket_token(token),
         :ok <- Relay.Leads.submit(params, session_id, %{request_id: request_id(conn)}) do
      conn
      |> put_status(:created)
      |> json(%{status: "delivered"})
    else
      {:error, :invalid_request} ->
        error(conn, 400, "invalid_request", "Revise os dados e confirme o envio.")

      {:error, :rate_limited} ->
        error(conn, 429, "rate_limit_exceeded", "O limite de envios foi atingido.")

      {:error, reason} when reason in [:invalid, :expired] ->
        error(conn, 401, "invalid_session", "A sessão expirou. Reabra o assistente.")

      {:error, :limiter_unavailable} ->
        error(conn, 503, "leads_unavailable", "O envio está temporariamente indisponível.")

      {:error, :unavailable} ->
        error(conn, 503, "lead_delivery_unavailable", "O envio ainda não está configurado.")

      _other ->
        error(conn, 401, "invalid_session", "A sessão expirou. Reabra o assistente.")
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" -> {:ok, token}
      _other -> {:error, :invalid}
    end
  end

  defp request_id(conn), do: conn.assigns[:request_id] || Process.get(:relay_request_id)

  defp error(conn, status, code, message),
    do: RelayWeb.ErrorResponse.send(conn, status, code, message)
end
