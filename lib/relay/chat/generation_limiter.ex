defmodule Relay.Chat.GenerationLimiter do
  @moduledoc """
  A node-local semaphore for active chat generations.

  A lease belongs to the calling process and is automatically reclaimed when
  that process exits. Channels keep the lease for the whole generation, so a
  disconnected client cannot leave capacity permanently occupied.
  """

  use GenServer

  @default_max_concurrent 8

  @type lease :: reference()

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec acquire(GenServer.server()) :: {:ok, lease()} | {:error, :overloaded}
  def acquire(server \\ __MODULE__), do: GenServer.call(server, {:acquire, self()})

  @spec release(lease(), GenServer.server()) :: :ok
  def release(lease, server \\ __MODULE__) when is_reference(lease),
    do: GenServer.call(server, {:release, lease})

  @doc false
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  @impl true
  def init(opts) do
    configured =
      Application.get_env(:relay, :chat_max_concurrent_generations, @default_max_concurrent)

    max_concurrent = Keyword.get(opts, :max_concurrent, configured)

    if is_integer(max_concurrent) and max_concurrent > 0 do
      {:ok, %{max_concurrent: max_concurrent, leases: %{}}}
    else
      {:stop, :invalid_generation_limit_configuration}
    end
  end

  @impl true
  def handle_call({:acquire, owner}, _from, %{leases: leases} = state) do
    if map_size(leases) < state.max_concurrent do
      lease = make_ref()
      monitor_ref = Process.monitor(owner)
      {:reply, {:ok, lease}, %{state | leases: Map.put(leases, lease, monitor_ref)}}
    else
      {:reply, {:error, :overloaded}, state}
    end
  end

  def handle_call({:release, lease}, _from, state), do: {:reply, :ok, remove_lease(state, lease)}

  def handle_call(:reset, _from, state) do
    Enum.each(state.leases, fn {_lease, monitor_ref} ->
      Process.demonitor(monitor_ref, [:flush])
    end)

    {:reply, :ok, %{state | leases: %{}}}
  end

  @impl true
  def handle_info({:DOWN, monitor_ref, :process, _owner, _reason}, state) do
    lease =
      Enum.find_value(state.leases, fn {lease, ref} ->
        if ref == monitor_ref, do: lease
      end)

    {:noreply, if(lease, do: remove_lease(state, lease), else: state)}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp remove_lease(%{leases: leases} = state, lease) do
    case Map.pop(leases, lease) do
      {nil, _} ->
        state

      {monitor_ref, remaining} ->
        Process.demonitor(monitor_ref, [:flush])
        %{state | leases: remaining}
    end
  end
end
