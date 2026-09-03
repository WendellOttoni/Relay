import Config

config :relay,
  ecto_repos: [],
  generators: [binary_id: true],
  environment: config_env(),
  allowed_origins: ["http://localhost:5173"],
  public_site_url: "http://localhost:5173",
  max_request_bytes: 65_536,
  request_timeout_ms: 90_000,
  session_ttl_seconds: 1_800,
  session_rate_limit: 10,
  session_rate_window_seconds: 60,
  turnstile_validator: Relay.Sessions.Turnstile.Disabled,
  chat_enabled: true,
  chat_provider: Relay.Chat.FakeProvider,
  chat_max_output_tokens: 1_000,
  chat_task_supervisor: Relay.ChatTaskSupervisor,
  chat_timeout_ms: 90_000,
  chat_max_concurrent_generations: 8,
  chat_limits: %{
    max_messages: 20,
    max_message_bytes: 8_192,
    max_request_bytes: 65_536
  },
  chat_rate_limit: %{max_requests: 10, window_ms: 60_000},
  runtime_config_errors: []

config :relay, RelayWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [json: RelayWeb.ErrorJSON], layout: false],
  pubsub_server: Relay.PubSub,
  live_view: [signing_salt: "relay-signing-salt"]

config :logger, :default_formatter,
  format: "timestamp=$time level=$level message=\"$message\" $metadata\n",
  metadata: [
    :request_id,
    :generation_id,
    :model,
    :result,
    :input_tokens,
    :output_tokens,
    :method,
    :path,
    :status,
    :duration_ms,
    :configuration_errors
  ]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
