import Config

config :relay, RelayWeb.Endpoint,
  cache_static_manifest: nil,
  server: true

config :logger, level: :info
