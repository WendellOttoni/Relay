defmodule Relay.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RelayWeb.Telemetry,
      Relay.Chat.GenerationMetrics,
      {Phoenix.PubSub, name: Relay.PubSub},
      {Relay.Sessions.RateLimiter, []},
      {Relay.Sessions.Turnstile.TokenStore, []},
      {Relay.Chat.RateLimiter, []},
      {Relay.Chat.GenerationLimiter, []},
      {Task.Supervisor, name: Relay.ChatTaskSupervisor},
      RelayWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Relay.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    RelayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
