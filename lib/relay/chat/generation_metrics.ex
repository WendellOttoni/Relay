defmodule Relay.Chat.GenerationMetrics do
  @moduledoc """
  In-memory, content-free counters for completed provider generations.

  This is deliberately an operational aid rather than a billing source of truth:
  it resets on restart and never receives prompts, generated text, credentials,
  session identifiers, request identifiers, or generation identifiers.
  """
  use GenServer

  require Logger

  @event [:relay, :chat, :generation, :stop]
  @handler_id {__MODULE__, :generation_stop}
  @failure_outcomes [:unavailable, :timeout, :rate_limited]

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "A safe snapshot suitable for a readiness-side diagnostic or local console."
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @doc false
  def handle_event(_event, measurements, metadata, _config) do
    GenServer.cast(__MODULE__, {:record, measurements, metadata})
  end

  @impl true
  def init(_) do
    :ok = :telemetry.attach(@handler_id, @event, &__MODULE__.handle_event/4, nil)

    {:ok,
     %{
       total: 0,
       outcomes: %{},
       input_tokens: 0,
       output_tokens: 0,
       duration_ms: 0,
       failures: [],
       alert_threshold: Application.get_env(:relay, :chat_failure_alert_threshold, 5),
       alert_window_ms: Application.get_env(:relay, :chat_failure_alert_window_ms, 300_000)
     }}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@handler_id)
    :ok
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, Map.take(state, [:total, :outcomes, :input_tokens, :output_tokens, :duration_ms]),
     state}
  end

  @impl true
  def handle_cast({:record, measurements, %{outcome: outcome}}, state)
      when is_atom(outcome) do
    state =
      state
      |> Map.update!(:total, &(&1 + 1))
      |> Map.update!(:duration_ms, &(&1 + non_negative(measurements[:duration_ms])))
      |> Map.update!(:input_tokens, &(&1 + non_negative(measurements[:input_tokens])))
      |> Map.update!(:output_tokens, &(&1 + non_negative(measurements[:output_tokens])))
      |> Map.update!(:outcomes, &Map.update(&1, outcome, 1, fn count -> count + 1 end))
      |> record_failure(outcome)

    {:noreply, state}
  end

  def handle_cast({:record, _measurements, _metadata}, state), do: {:noreply, state}

  defp record_failure(state, outcome) when outcome not in @failure_outcomes, do: state

  defp record_failure(state, outcome) do
    now = System.monotonic_time(:millisecond)
    failures = [now | Enum.filter(state.failures, &(now - &1 <= state.alert_window_ms))]

    if length(failures) == state.alert_threshold do
      Logger.warning("chat_generation_failure_threshold_reached",
        outcome: outcome,
        failures_in_window: length(failures),
        window_ms: state.alert_window_ms
      )
    end

    %{state | failures: failures}
  end

  defp non_negative(value) when is_integer(value) and value >= 0, do: value
  defp non_negative(_value), do: 0
end
