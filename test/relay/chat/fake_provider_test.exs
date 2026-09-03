defmodule Relay.Chat.FakeProviderTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.{FakeProvider, Message}

  test "emits configured events deterministically and returns configured result" do
    caller = self()
    events = [{:delta, "a"}, {:delta, "b"}, {:usage, %{output_tokens: 2}}]

    assert {:ok, :length} =
             FakeProvider.stream(
               [%Message{role: :user, content: "test"}],
               &send(caller, &1),
               events: events,
               result: {:ok, :length}
             )

    assert_receive {:delta, "a"}
    assert_receive {:delta, "b"}
    assert_receive {:usage, %{output_tokens: 2}}
  end

  test "can fail after emitting deltas" do
    caller = self()

    assert {:error, :unavailable} =
             FakeProvider.stream([], &send(caller, &1),
               events: [{:delta, "partial"}],
               result: {:error, :unavailable}
             )

    assert_receive {:delta, "partial"}
  end
end
