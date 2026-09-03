import Config

if config_env() == :prod do
  host = System.get_env("PHX_HOST")
  {port, port_errors} = Relay.Config.parse_port(System.get_env("PORT"), 4000)
  {log_level, log_level_errors} = Relay.Config.parse_log_level(System.get_env("LOG_LEVEL"), :info)
  secret_key_base = System.get_env("SECRET_KEY_BASE")
  origins_value = System.get_env("ALLOWED_ORIGINS")
  public_site_url = System.get_env("PUBLIC_SITE_URL")

  {chat_enabled, chat_enabled_errors} =
    Relay.Config.parse_boolean(System.get_env("CHAT_ENABLED"), "CHAT_ENABLED", false)

  {chat_max_output_tokens, output_token_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_MAX_OUTPUT_TOKENS"),
      "CHAT_MAX_OUTPUT_TOKENS",
      1_000
    )

  {chat_timeout_ms, timeout_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_TIMEOUT_MS"),
      "CHAT_TIMEOUT_MS",
      90_000
    )

  {chat_max_concurrent_generations, concurrent_generation_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_MAX_CONCURRENT_GENERATIONS"),
      "CHAT_MAX_CONCURRENT_GENERATIONS",
      8
    )

  {session_ttl_seconds, session_ttl_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_SESSION_TTL_SECONDS"),
      "CHAT_SESSION_TTL_SECONDS",
      1_800
    )

  {chat_max_messages, max_messages_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_MAX_MESSAGES"),
      "CHAT_MAX_MESSAGES",
      20
    )

  {chat_max_message_bytes, max_message_bytes_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_MAX_MESSAGE_BYTES"),
      "CHAT_MAX_MESSAGE_BYTES",
      8_192
    )

  {chat_max_request_bytes, max_request_bytes_errors} =
    Relay.Config.parse_positive_integer(
      System.get_env("CHAT_MAX_REQUEST_BYTES"),
      "CHAT_MAX_REQUEST_BYTES",
      65_536
    )

  openrouter_api_key = System.get_env("OPENROUTER_API_KEY")
  openrouter_model = System.get_env("OPENROUTER_MODEL")
  system_prompt = System.get_env("SYSTEM_PROMPT")
  turnstile_secret_key = System.get_env("TURNSTILE_SECRET_KEY")
  turnstile_expected_hostname = System.get_env("TURNSTILE_EXPECTED_HOSTNAME")
  turnstile_expected_action = System.get_env("TURNSTILE_EXPECTED_ACTION")

  {allowed_origins, origin_errors} = Relay.Config.parse_origins(origins_value, :prod)

  errors =
    []
    |> Relay.Config.require_value("PHX_HOST", host)
    # Render's generated secret is a Base64-encoded 256-bit value (44 text
    # bytes including padding). Requiring 32 characters preserves that entropy
    # floor without rejecting the platform-generated value.
    |> Relay.Config.require_secret("SECRET_KEY_BASE", secret_key_base, 32)
    |> Relay.Config.require_value("PUBLIC_SITE_URL", public_site_url)
    |> Kernel.++(origin_errors)
    |> Kernel.++(chat_enabled_errors)
    |> Kernel.++(port_errors)
    |> Kernel.++(log_level_errors)
    |> Kernel.++(output_token_errors)
    |> Kernel.++(timeout_errors)
    |> Kernel.++(concurrent_generation_errors)
    |> Kernel.++(session_ttl_errors)
    |> Kernel.++(max_messages_errors)
    |> Kernel.++(max_message_bytes_errors)
    |> Kernel.++(max_request_bytes_errors)

  openrouter_errors =
    if chat_enabled do
      []
      |> Relay.Config.require_secret("OPENROUTER_API_KEY", openrouter_api_key, 1)
      |> Relay.Config.require_value("OPENROUTER_MODEL", openrouter_model)
      |> Relay.Config.require_value("SYSTEM_PROMPT", system_prompt)
    else
      []
    end

  turnstile_errors =
    if chat_enabled do
      []
      |> Relay.Config.require_secret("TURNSTILE_SECRET_KEY", turnstile_secret_key, 1)
      |> Relay.Config.require_value("TURNSTILE_EXPECTED_HOSTNAME", turnstile_expected_hostname)
      |> Relay.Config.require_value("TURNSTILE_EXPECTED_ACTION", turnstile_expected_action)
    else
      []
    end

  # Any invalid runtime setting disables the public chat. This ensures a typo in
  # a limit or deployment value cannot accidentally expose the provider.
  provider_configured? =
    chat_enabled and errors == [] and openrouter_errors == [] and turnstile_errors == []

  chat_provider =
    if provider_configured? do
      {Relay.Integrations.OpenRouter,
       api_key: openrouter_api_key,
       model: openrouter_model,
       system_prompt: system_prompt,
       max_tokens: chat_max_output_tokens,
       public_site_url: public_site_url,
       connect_timeout: 10_000,
       receive_timeout: 15_000,
       request_timeout: chat_timeout_ms}
    else
      Relay.Chat.FakeProvider
    end

  config :relay,
    environment: :prod,
    allowed_origins: allowed_origins,
    public_site_url: public_site_url,
    chat_enabled: provider_configured?,
    chat_provider: chat_provider,
    chat_max_output_tokens: chat_max_output_tokens,
    chat_timeout_ms: chat_timeout_ms,
    chat_max_concurrent_generations: chat_max_concurrent_generations,
    max_request_bytes: chat_max_request_bytes,
    session_ttl_seconds: session_ttl_seconds,
    chat_limits: %{
      max_messages: chat_max_messages,
      max_message_bytes: chat_max_message_bytes,
      max_request_bytes: chat_max_request_bytes
    },
    turnstile_validator:
      if(provider_configured?,
        do: Relay.Sessions.Turnstile.Cloudflare,
        else: Relay.Sessions.Turnstile.Disabled
      ),
    turnstile_secret_key: turnstile_secret_key,
    turnstile_expected_hostname: turnstile_expected_hostname,
    turnstile_expected_action: turnstile_expected_action,
    runtime_config_errors: errors ++ openrouter_errors ++ turnstile_errors

  config :relay, RelayWeb.Endpoint,
    url: [host: host || "invalid.local", port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    check_origin: Relay.Config.websocket_origins(allowed_origins),
    secret_key_base: secret_key_base || String.duplicate("0", 64)

  config :logger, level: log_level
else
  origins_value = System.get_env("ALLOWED_ORIGINS")
  default_origins = Application.compile_env!(:relay, :allowed_origins)

  {allowed_origins, errors} =
    case origins_value do
      nil -> {default_origins, []}
      value -> Relay.Config.parse_origins(value, config_env())
    end

  config :relay,
    allowed_origins: allowed_origins,
    public_site_url:
      System.get_env("PUBLIC_SITE_URL") || Application.compile_env!(:relay, :public_site_url),
    runtime_config_errors: errors

  config :relay, RelayWeb.Endpoint, check_origin: Relay.Config.websocket_origins(allowed_origins)
end
