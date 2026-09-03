defmodule RelayWeb.Plugs.RequestLogger do
  @moduledoc false
  @behaviour Plug
  require Logger

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    started_at = System.monotonic_time()

    Plug.Conn.register_before_send(conn, fn conn ->
      duration_ms =
        System.convert_time_unit(System.monotonic_time() - started_at, :native, :microsecond) /
          1_000

      Logger.info("request_completed",
        request_id: request_id(conn),
        method: conn.method,
        path: conn.request_path,
        status: conn.status,
        duration_ms: Float.round(duration_ms, 3)
      )

      conn
    end)
  end

  defp request_id(conn) do
    conn
    |> Plug.Conn.get_resp_header("x-request-id")
    |> List.first()
  end
end
