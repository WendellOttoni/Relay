import Config

if config_env() == :prod do
  host = System.get_env("PHX_HOST")
  port = String.to_integer(System.get_env("PORT") || "4000")
  secret_key_base = System.get_env("SECRET_KEY_BASE")
  origins_value = System.get_env("ALLOWED_ORIGINS")
  public_site_url = System.get_env("PUBLIC_SITE_URL")

  {allowed_origins, origin_errors} = Relay.Config.parse_origins(origins_value, :prod)

  errors =
    []
    |> Relay.Config.require_value("PHX_HOST", host)
    |> Relay.Config.require_secret("SECRET_KEY_BASE", secret_key_base, 64)
    |> Relay.Config.require_value("PUBLIC_SITE_URL", public_site_url)
    |> Kernel.++(origin_errors)

  config :relay,
    environment: :prod,
    allowed_origins: allowed_origins,
    public_site_url: public_site_url,
    runtime_config_errors: errors

  config :relay, RelayWeb.Endpoint,
    url: [host: host || "invalid.local", port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    check_origin: Relay.Config.websocket_origins(allowed_origins),
    secret_key_base: secret_key_base || String.duplicate("0", 64)
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

  config :relay, RelayWeb.Endpoint,
    check_origin: Relay.Config.websocket_origins(allowed_origins)
end
