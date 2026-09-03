defmodule RelayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :relay

  @session_options [
    store: :cookie,
    key: "_relay_key",
    signing_salt: "relay-cookie-signing"
  ]

  # `check_origin: true` (boolean) is a Phoenix option that compares the
  # request origin against this Endpoint's own `:url` host, which is not the
  # validated allow list. Omitting it here makes the transport fall back to
  # `endpoint.config(:check_origin)`, which is the same list configured in
  # `config/runtime.exs` from `ALLOWED_ORIGINS` (see F1.6).
  socket "/socket", RelayWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug RelayWeb.Plugs.RequestId
  plug RelayWeb.Plugs.RequestLogger
  plug RelayWeb.Plugs.CORS

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: Application.compile_env(:relay, :max_request_bytes, 65_536)

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RelayWeb.Router
end
