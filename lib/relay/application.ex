defmodule Relay.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      RelayWeb.Telemetry,
      Relay.Chat.GenerationMetrics,
      {Phoenix.PubSub, name: Relay.PubSub},
      {Relay.Sessions.RateLimiter, []},
      {Relay.Chat.RateLimiter, []},
      {Relay.Leads.RateLimiter, []},
      {Relay.Chat.GenerationLimiter, []},
      {Task.Supervisor, name: Relay.ChatTaskSupervisor},
      RelayWeb.Endpoint
    ]

    case Supervisor.start_link(children, strategy: :one_for_one, name: Relay.Supervisor) do
      {:ok, _pid} = result ->
        log_runtime_readiness()
        result

      error ->
        error
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    RelayWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp log_runtime_readiness do
    if Relay.Config.ready?() do
      Logger.info("relay_runtime_configuration_ready")
    else
      # The errors contain validation messages and variable names only, never
      # configuration values or secrets.
      errors = Relay.Config.errors() |> Enum.join("; ")
      Logger.error("relay_runtime_configuration_invalid errors=#{errors}")
    end
  end
end
