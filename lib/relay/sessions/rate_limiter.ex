defmodule Relay.Sessions.RateLimiter do
  @moduledoc """
  Small in-memory fixed-window limiter for anonymous session creation.

  It is intentionally local to one Relay instance. The OpenRouter budget remains
  the final global cost barrier if the service is ever scaled horizontally.
  """

  use GenServer

  @default_limit 10
  @default_window_seconds 60

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec allow?(term(), GenServer.server()) :: :ok | {:error, atom()}
  def allow?(network_key, server \\ __MODULE__) do
    GenServer.call(server, {:allow, network_key})
  catch
    :exit, _reason -> {:error, :limiter_unavailable}
  end

  @impl true
  def init(opts) do
    limit =
      Keyword.get(opts, :limit, Application.get_env(:relay, :session_rate_limit, @default_limit))

    window_seconds =
      Keyword.get(
        opts,
        :window_seconds,
        Application.get_env(:relay, :session_rate_window_seconds, @default_window_seconds)
      )

    {:ok,
     %{
       entries: %{},
       limit: positive(limit, @default_limit),
       window_ms: positive(window_seconds, @default_window_seconds) * 1_000
     }}
  end

  @impl true
  def handle_call({:allow, network_key}, _from, state) do
    now = System.monotonic_time(:millisecond)
    {count, window_started_at} = Map.get(state.entries, network_key, {0, now})

    {count, window_started_at} =
      if now - window_started_at >= state.window_ms,
        do: {0, now},
        else: {count, window_started_at}

    if count < state.limit do
      entries = Map.put(state.entries, network_key, {count + 1, window_started_at})
      {:reply, :ok, %{state | entries: entries}}
    else
      {:reply, {:error, :rate_limited}, state}
    end
  end

  defp positive(value, _default) when is_integer(value) and value > 0, do: value
  defp positive(_value, default), do: default
end
