defmodule RelayWeb.Plugs.Parsers do
  @moduledoc false
  @behaviour Plug

  @default_max_request_bytes 65_536

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn
    |> Plug.Parsers.call(
      Plug.Parsers.init(
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library(),
        length: max_request_bytes()
      )
    )
  end

  defp max_request_bytes do
    case Application.get_env(:relay, :max_request_bytes, @default_max_request_bytes) do
      value when is_integer(value) and value > 0 -> value
      _invalid -> @default_max_request_bytes
    end
  end
end
