defmodule Relay.Leads.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Relay.Leads.RateLimiter

  test "limits deliveries independently by session" do
    name =
      Module.concat(__MODULE__, String.to_atom("Limiter#{System.unique_integer([:positive])}"))

    start_supervised!({RateLimiter, name: name, limit: 2, window_seconds: 60})

    assert :ok = RateLimiter.allow?("session-a", name)
    assert :ok = RateLimiter.allow?("session-a", name)
    assert {:error, :rate_limited} = RateLimiter.allow?("session-a", name)
    assert :ok = RateLimiter.allow?("session-b", name)
  end
end
