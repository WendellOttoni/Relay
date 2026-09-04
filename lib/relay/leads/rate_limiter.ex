defmodule Relay.Leads.RateLimiter do
  @moduledoc "In-memory limiter for authenticated lead submissions."

  use GenServer

  @default_limit 2
  @default_window_seconds 3_600

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec allow?(String.t(), GenServer.server()) :: :ok | {:error, atom()}
  def allow?(session_id, server \\ __MODULE__) do
    GenServer.call(server, {:allow, session_id})
  catch
    :exit, _reason -> {:error, :limiter_unavailable}
  end

  @impl true
  def init(opts) do
    limit =
      Keyword.get(opts, :limit, Application.get_env(:relay, :lead_rate_limit, @default_limit))

    window_seconds =
      Keyword.get(
        opts,
        :window_seconds,
        Application.get_env(:relay, :lead_rate_window_seconds, @default_window_seconds)
      )

    {:ok,
     %{
       entries: %{},
       limit: positive(limit, @default_limit),
       window_ms: positive(window_seconds, @default_window_seconds) * 1_000
     }}
  end

  @impl true
  def handle_call({:allow, session_id}, _from, state) do
    now = System.monotonic_time(:millisecond)

    entries =
      Map.filter(state.entries, fn {_key, {_count, started}} ->
        now - started < state.window_ms
      end)

    {count, started} = Map.get(entries, session_id, {0, now})
    {count, started} = if now - started >= state.window_ms, do: {0, now}, else: {count, started}

    if count < state.limit do
      {:reply, :ok, %{state | entries: Map.put(entries, session_id, {count + 1, started})}}
    else
      {:reply, {:error, :rate_limited}, %{state | entries: entries}}
    end
  end

  defp positive(value, _default) when is_integer(value) and value > 0, do: value
  defp positive(_value, default), do: default
end
