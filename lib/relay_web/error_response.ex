defmodule RelayWeb.ErrorResponse do
  @moduledoc false

  import Plug.Conn

  def send(conn, status, code, message) do
    body =
      Jason.encode!(%{
        error: %{
          code: code,
          message: message,
          requestId: request_id(conn)
        }
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end

  def request_id(conn) do
    conn
    |> get_resp_header("x-request-id")
    |> List.first()
  end
end
