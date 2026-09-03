defmodule Relay.Sessions.Turnstile.Disabled do
  @moduledoc """
  Fail-closed validator used until a real Turnstile integration is configured.
  """

  @behaviour Relay.Sessions.TurnstileValidator

  @impl true
  def verify(_token, _context), do: {:error, :validator_unavailable}
end
