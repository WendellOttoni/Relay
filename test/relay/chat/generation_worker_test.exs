defmodule Relay.Chat.GenerationWorkerTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.{GenerationWorker, Request}

  setup do
    supervisor = start_supervised!(Task.Supervisor)
    request = %Request{messages: []}
    ids = %{generation_id: "generation", request_id: "request"}
    %{supervisor: supervisor, request: request, ids: ids}
  end

  test "serializes deltas and terminal events", context do
    {:ok, worker} =
      GenerationWorker.start_child(
        context.supervisor,
        self(),
        Relay.Chat.FakeProvider,
        context.request,
        context.ids,
        events: [{:delta, "a"}, {:delta, "b"}, {:usage, %{input_tokens: 3, secret: 9}}]
      )

    assert_receive {:chat_generation_event, ^worker, _, :started}
    assert_receive {:chat_generation_event, ^worker, _, {:delta, 1, "a"}}
    assert_receive {:chat_generation_event, ^worker, _, {:delta, 2, "b"}}
    assert_receive {:chat_generation_event, ^worker, _, {:usage, %{input_tokens: 3}}}
    assert_receive {:chat_generation_event, ^worker, _, {:completed, :stop}}
  end

  test "maps provider failures to safe public errors", context do
    {:ok, worker} =
      GenerationWorker.start_child(
        context.supervisor,
        self(),
        Relay.Chat.FakeProvider,
        context.request,
        context.ids,
        events: [],
        result: {:error, {:raw_provider_response, "secret"}}
      )

    assert_receive {:chat_generation_event, ^worker, _, :started}
    assert_receive {:chat_generation_event, ^worker, _, {:error, :internal_error}}
    refute_receive {:chat_generation_event, ^worker, _, {:error, {:raw_provider_response, _}}}
  end

  test "cancels a provider waiting indefinitely", context do
    {:ok, worker} =
      GenerationWorker.start_child(
        context.supervisor,
        self(),
        Relay.Chat.FakeProvider,
        context.request,
        context.ids,
        events: [],
        wait: true
      )

    monitor = Process.monitor(worker)
    assert_receive {:chat_generation_event, ^worker, _, :started}

    assert :ok = GenerationWorker.cancel(worker)
    assert_receive {:chat_generation_event, ^worker, _, {:completed, :cancelled}}
    assert_receive {:DOWN, ^monitor, :process, ^worker, :normal}
    refute_receive {:chat_generation_event, ^worker, _, {:delta, _, _}}
  end

  test "terminates a provider when the generation deadline is reached", context do
    {:ok, worker} =
      GenerationWorker.start_child(
        context.supervisor,
        self(),
        Relay.Chat.FakeProvider,
        context.request,
        context.ids,
        [events: [], wait: true],
        timeout_ms: 10
      )

    monitor = Process.monitor(worker)
    assert_receive {:chat_generation_event, ^worker, _, :started}
    assert_receive {:chat_generation_event, ^worker, _, {:error, :provider_timeout}}, 100
    assert_receive {:DOWN, ^monitor, :process, ^worker, :normal}
  end

  test "stops when its channel exits", context do
    test_process = self()

    channel =
      spawn(fn ->
        receive do
          event -> send(test_process, event)
        end

        receive do
          :stop -> :ok
        end
      end)

    {:ok, worker} =
      GenerationWorker.start_child(
        context.supervisor,
        channel,
        Relay.Chat.FakeProvider,
        context.request,
        context.ids,
        events: [],
        wait: true
      )

    monitor = Process.monitor(worker)
    assert_receive {:chat_generation_event, ^worker, _, :started}
    Process.exit(channel, :kill)
    assert_receive {:DOWN, ^monitor, :process, ^worker, :normal}
  end
end
