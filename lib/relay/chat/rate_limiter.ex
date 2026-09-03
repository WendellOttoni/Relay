defmodule Relay.Chat.RateLimiter do
  @moduledoc """
  An in-memory fixed-window generation limiter keyed by anonymous session.

  The optional timestamp accepted by `allow?/2` exists to make boundary tests
  deterministic. State is intentionally local to one Relay instance; a future
  multi-instance deployment must replace it with a shared limiter.
  """

  use GenServer

  @default_max_requests 10
  @default_window_ms 60_000

  @type timestamp_ms :: integer()

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec allow?(String.t(), timestamp_ms()) :: boolean()
  def allow?(session_id, now \\ System.monotonic_time(:millisecond))
      when is_binary(session_id) and is_integer(now) do
    GenServer.call(__MODULE__, {:allow, session_id, now})
  end

  @doc false
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(opts) do
    configured = Application.get_env(:relay, :chat_rate_limit, %{}) |> Map.new()

    max_requests =
      Keyword.get(opts, :max_requests, Map.get(configured, :max_requests, @default_max_requests))

    window_ms = Keyword.get(opts, :window_ms, Map.get(configured, :window_ms, @default_window_ms))

    if positive_integer?(max_requests) and positive_integer?(window_ms) do
      {:ok, %{entries: %{}, max_requests: max_requests, window_ms: window_ms}}
    else
      {:stop, :invalid_rate_limit_configuration}
    end
  end

  @impl true
  def handle_call({:allow, session_id, now}, _from, state) do
    entries = prune_expired(state.entries, now, state.window_ms)

    case Map.get(entries, session_id) do
      nil ->
        entry = %{window_started_at: now, count: 1}
        {:reply, true, %{state | entries: Map.put(entries, session_id, entry)}}

      %{count: count} = entry when count < state.max_requests ->
        updated = %{entry | count: count + 1}
        {:reply, true, %{state | entries: Map.put(entries, session_id, updated)}}

      _entry ->
        {:reply, false, %{state | entries: entries}}
    end
  end

  def handle_call(:reset, _from, state), do: {:reply, :ok, %{state | entries: %{}}}

  defp prune_expired(entries, now, window_ms) do
    Map.reject(entries, fn {_session_id, entry} ->
      now < entry.window_started_at or now - entry.window_started_at >= window_ms
    end)
  end

  defp positive_integer?(value), do: is_integer(value) and value > 0
end
