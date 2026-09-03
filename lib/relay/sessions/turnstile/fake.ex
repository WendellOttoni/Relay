defmodule Relay.Sessions.Turnstile.Fake do
  @moduledoc """
  Deterministic validator intended for development and tests.

  Tokens must be explicitly allow-listed with the `:turnstile_fake_tokens`
  application setting. The fake therefore also fails closed when unconfigured.
  """

  @behaviour Relay.Sessions.TurnstileValidator

  @impl true
  def verify(token, _context) do
    accepted_tokens = Application.get_env(:relay, :turnstile_fake_tokens, [])

    if token in accepted_tokens, do: :ok, else: {:error, :invalid_challenge}
  end
end
