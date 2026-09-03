import Config

config :relay, RelayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: ["//localhost:5173"],
  code_reloader: true,
  debug_errors: true,
  secret_key_base: String.duplicate("development-only-secret-key-base-", 2),
  watchers: []

config :logger, level: :debug
config :phoenix, :plug_init_mode, :runtime
