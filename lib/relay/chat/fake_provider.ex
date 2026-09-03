defmodule Relay.Chat.FakeProvider do
  @moduledoc """
  Deterministic provider used locally and in tests.

  Its behavior is configured through options, which keeps unit tests independent
  from global state. Supported options are `:events`, `:result`, `:wait`, and
  `:delay_ms`. Waiting and delays are opt-in; normal tests use no real timer.
  """

  @behaviour Relay.Chat.Provider

  @default_events [{:delta, "Olá"}, {:delta, "!"}, {:usage, %{input_tokens: 1, output_tokens: 2}}]

  @impl true
  def stream(_messages, emit, opts) do
    Enum.each(Keyword.get(opts, :events, @default_events), fn event ->
      maybe_delay(Keyword.get(opts, :delay_ms, 0))
      emit.(event)
    end)

    if Keyword.get(opts, :wait, false) do
      receive do
        :release -> Keyword.get(opts, :result, {:ok, :stop})
      end
    else
      Keyword.get(opts, :result, {:ok, :stop})
    end
  end

  defp maybe_delay(0), do: :ok
  defp maybe_delay(milliseconds) when is_integer(milliseconds) and milliseconds > 0,
    do: Process.sleep(milliseconds)
end
