defmodule RelayWeb.Plugs.CORS do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  @allowed_methods "GET, POST, OPTIONS"
  @allowed_headers ["content-type", "x-request-id"]
  @max_age "600"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    origin = conn |> get_req_header("origin") |> List.first()

    cond do
      is_nil(origin) ->
        conn

      origin in allowed_origins() ->
        conn
        |> put_resp_header("access-control-allow-origin", origin)
        |> put_resp_header("access-control-allow-methods", @allowed_methods)
        |> put_resp_header("access-control-allow-headers", Enum.join(@allowed_headers, ", "))
        |> put_resp_header("access-control-max-age", @max_age)
        |> put_resp_header("vary", "origin")
        |> maybe_complete_preflight()

      conn.method == "OPTIONS" ->
        conn
        |> RelayWeb.ErrorResponse.send(403, "origin_forbidden", "Origem não autorizada.")
        |> halt()

      true ->
        conn
    end
  end

  defp maybe_complete_preflight(%{method: "OPTIONS"} = conn) do
    if valid_preflight?(conn) do
      conn |> send_resp(204, "") |> halt()
    else
      conn
      |> RelayWeb.ErrorResponse.send(403, "preflight_rejected", "Preflight não autorizado.")
      |> halt()
    end
  end

  defp maybe_complete_preflight(conn), do: conn

  defp allowed_origins, do: Application.get_env(:relay, :allowed_origins, [])

  defp valid_preflight?(conn) do
    requested_method = conn |> get_req_header("access-control-request-method") |> List.first()

    requested_headers =
      conn
      |> get_req_header("access-control-request-headers")
      |> List.first("")
      |> String.split(",", trim: true)
      |> Enum.map(&(String.trim(&1) |> String.downcase()))

    requested_method in String.split(@allowed_methods, ", ") and
      Enum.all?(requested_headers, &(&1 in @allowed_headers))
  end
end
