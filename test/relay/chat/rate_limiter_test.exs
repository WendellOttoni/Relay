defmodule Relay.Chat.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.RateLimiter

  setup do
    name = Module.concat(__MODULE__, String.to_atom("Limiter#{System.unique_integer([:positive])}"))

    limiter =
      start_supervised!(
        {RateLimiter, name: name, max_requests: 2, window_ms: 100}
      )

    %{limiter: limiter}
  end

  test "limits each session independently and resets at the window boundary", %{limiter: limiter} do
    assert GenServer.call(limiter, {:allow, "session-a", 1_000})
    assert GenServer.call(limiter, {:allow, "session-a", 1_001})
    refute GenServer.call(limiter, {:allow, "session-a", 1_099})

    assert GenServer.call(limiter, {:allow, "session-b", 1_099})
    assert GenServer.call(limiter, {:allow, "session-a", 1_100})
  end

  test "cleans expired session entries and handles a monotonic clock reset", %{limiter: limiter} do
    assert GenServer.call(limiter, {:allow, "old-session", 5_000})
    assert GenServer.call(limiter, {:allow, "new-session", 4_000})

    state = :sys.get_state(limiter)
    refute Map.has_key?(state.entries, "old-session")
    assert Map.has_key?(state.entries, "new-session")
  end

  test "rejects invalid configuration" do
    name = Module.concat(__MODULE__, InvalidLimiter)

    assert {:error, :invalid_rate_limit_configuration} =
             RateLimiter.start_link(name: name, max_requests: 0, window_ms: 100)
  end
end
