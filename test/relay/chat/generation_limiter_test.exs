defmodule Relay.Chat.GenerationLimiterTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.GenerationLimiter

  test "a lease is reclaimed when its acquiring process exits" do
    name =
      String.to_atom("generation_limiter_owner_#{System.unique_integer([:positive])}")

    start_supervised!({GenerationLimiter, name: name, max_concurrent: 1})
    parent = self()

    owner =
      spawn(fn ->
        send(parent, {:lease, GenerationLimiter.acquire(name)})

        receive do
          :stop -> :ok
        end
      end)

    assert_receive {:lease, {:ok, _lease}}
    assert {:error, :overloaded} = GenerationLimiter.acquire(name)
    Process.exit(owner, :kill)
    Process.sleep(10)
    assert {:ok, lease} = GenerationLimiter.acquire(name)
    assert :ok = GenerationLimiter.release(lease, name)
  end
end
