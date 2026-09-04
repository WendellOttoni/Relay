import Config

config :relay, RelayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: String.duplicate("test-only-secret-key-base-", 3),
  server: false

config :logger, level: :info
config :phoenix, :plug_init_mode, :runtime

config :relay,
  chat_enabled: true,
  chat_provider: Relay.Chat.FakeProvider
