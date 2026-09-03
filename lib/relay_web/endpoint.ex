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

  # The body limit is runtime configuration. Keeping its initialization in a
  # small plug avoids baking the development value into a production release.
  plug RelayWeb.Plugs.Parsers

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RelayWeb.Router
end
