defmodule Mix.Tasks.Relay.SmokeOpenrouter do
  @shortdoc "Runs one explicitly authorized, low-cost OpenRouter smoke generation"

  @moduledoc """
  Runs one short real provider request only when explicitly enabled.

      RELAY_RUN_OPENROUTER_SMOKE=true mix relay.smoke_openrouter

  It is intentionally not part of `mix test` or `mix check`. The task prints
  only event categories and counts, never provider text or configuration.
  """
  use Mix.Task

  alias Relay.Chat.Message

  @impl true
  def run([]) do
    unless System.get_env("RELAY_RUN_OPENROUTER_SMOKE") == "true" do
      Mix.raise(
        "Refusing network call. Set RELAY_RUN_OPENROUTER_SMOKE=true after approving the budget."
      )
    end

    Mix.Task.run("app.start")

    case Application.get_env(:relay, :chat_provider) do
      {Relay.Integrations.OpenRouter, opts} when is_list(opts) -> run_smoke(opts)
      _ -> Mix.raise("OpenRouter is not enabled by the active runtime configuration.")
    end
  end

  def run(_args), do: Mix.raise("This task accepts no arguments.")

  defp run_smoke(opts) do
    parent = self()

    result =
      Relay.Integrations.OpenRouter.stream(
        [%Message{role: :user, content: "Responda somente: ok"}],
        fn event -> send(parent, {:smoke_event, event}) end,
        opts
      )

    events = collect([])
    delta_count = Enum.count(events, &match?({:delta, _}, &1))
    usage? = Enum.any?(events, &match?({:usage, _}, &1))

    Mix.shell().info(
      "OpenRouter smoke result=#{inspect(result)} deltas=#{delta_count} usage=#{usage?}"
    )
  end

  defp collect(events) do
    receive do
      {:smoke_event, event} -> collect([event | events])
    after
      0 -> Enum.reverse(events)
    end
  end
end
