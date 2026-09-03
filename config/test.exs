import Config

config :relay, RelayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: String.duplicate("test-only-secret-key-base-", 3),
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :relay,
  turnstile_validator: Relay.Sessions.Turnstile.Fake,
  chat_provider: Relay.Chat.FakeProvider
