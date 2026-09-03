defmodule Relay.Chat.GenerationWorker do
  @moduledoc """
  Coordinates one generation and binds its lifetime to the owning Channel.

  The coordinator and provider call are separate supervised tasks. This is
  intentional: the coordinator can terminate a provider that is blocked in IO,
  while still serializing every event sent to the Channel.
  """

  require Logger

  @type ids :: %{generation_id: String.t(), request_id: String.t()}

  @spec start_child(
          module() | atom(),
          pid(),
          module(),
          Relay.Chat.Request.t(),
          ids(),
          keyword(),
          keyword()
        ) ::
          {:ok, pid()} | {:error, term()}
  def start_child(
        supervisor,
        channel,
        provider,
        request,
        ids,
        provider_opts \\ [],
        worker_opts \\ []
      ) do
    Task.Supervisor.start_child(supervisor, fn ->
      run(supervisor, channel, provider, request, ids, provider_opts, worker_opts)
    end)
  end

  @spec cancel(pid()) :: :ok
  def cancel(worker) when is_pid(worker) do
    send(worker, :cancel)
    :ok
  end

  defp run(supervisor, channel, provider, request, ids, provider_opts, worker_opts) do
    channel_ref = Process.monitor(channel)
    coordinator = self()
    timeout_ms = Keyword.get(worker_opts, :timeout_ms, 90_000)
    Process.send_after(self(), :generation_timeout, timeout_ms)

    provider_opts =
      Keyword.merge(provider_opts, request_id: ids.request_id, generation_id: ids.generation_id)

    task =
      Task.Supervisor.async_nolink(supervisor, fn ->
        provider.stream(
          request.messages,
          &send(coordinator, {:provider_event, &1}),
          provider_opts
        )
      end)

    send(channel, {:chat_generation_event, self(), ids, :started})
    loop(channel, channel_ref, task, ids, 0)
  end

  defp loop(channel, channel_ref, task, ids, sequence) do
    receive do
      {:provider_event, {:delta, text}} when is_binary(text) and text != "" ->
        next_sequence = sequence + 1
        notify(channel, self(), ids, {:delta, next_sequence, text})
        loop(channel, channel_ref, task, ids, next_sequence)

      {:provider_event, {:usage, usage}} when is_map(usage) ->
        notify(channel, self(), ids, {:usage, sanitize_usage(usage)})
        loop(channel, channel_ref, task, ids, sequence)

      {ref, result} when ref == task.ref ->
        Process.demonitor(task.ref, [:flush])
        finish(channel, ids, result)

      {:DOWN, ref, :process, _pid, _reason} when ref == task.ref ->
        Logger.warning("chat provider task stopped unexpectedly")
        notify(channel, self(), ids, {:error, :internal_error})

      :cancel ->
        stop_provider(task)
        notify(channel, self(), ids, {:completed, :cancelled})

      :generation_timeout ->
        stop_provider(task)
        notify(channel, self(), ids, {:error, :provider_timeout})

      {:DOWN, ref, :process, _pid, _reason} when ref == channel_ref ->
        stop_provider(task)

      _other ->
        loop(channel, channel_ref, task, ids, sequence)
    end
  end

  defp finish(channel, ids, {:ok, reason}) when reason in [:stop, :length],
    do: notify(channel, self(), ids, {:completed, reason})

  defp finish(channel, ids, {:error, reason}),
    do: notify(channel, self(), ids, {:error, public_error(reason)})

  defp finish(channel, ids, _unexpected),
    do: notify(channel, self(), ids, {:error, :internal_error})

  defp stop_provider(%Task{} = task) do
    case Task.shutdown(task, :brutal_kill) do
      nil -> :ok
      _result -> :ok
    end
  end

  defp notify(channel, worker, ids, event),
    do: send(channel, {:chat_generation_event, worker, ids, event})

  defp sanitize_usage(usage) do
    %{}
    |> maybe_put(:input_tokens, usage[:input_tokens])
    |> maybe_put(:output_tokens, usage[:output_tokens])
  end

  defp maybe_put(map, _key, value) when not is_integer(value) or value < 0, do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp public_error(:unavailable), do: :provider_unavailable
  defp public_error(:timeout), do: :provider_timeout
  defp public_error(:rate_limited), do: :rate_limit_exceeded
  defp public_error(_), do: :internal_error
end
