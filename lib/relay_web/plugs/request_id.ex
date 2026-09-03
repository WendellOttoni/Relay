defmodule RelayWeb.Plugs.RequestId do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: Plug.RequestId.init(opts)

  @impl true
  def call(conn, opts) do
    conn = Plug.RequestId.call(conn, opts)
    Process.put(:relay_request_id, request_id(conn))
    conn
  end

  defp request_id(conn) do
    case Plug.Conn.get_resp_header(conn, "x-request-id") do
      [request_id | _] -> request_id
      [] -> nil
    end
  end
end
