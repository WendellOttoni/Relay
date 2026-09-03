defmodule Relay.Sessions.TurnstileValidator do
  @moduledoc """
  Contract used to validate the anti-abuse challenge before issuing a session.

  Implementations are responsible for checking the token as well as the expected
  Turnstile hostname and action present in the context.
  """

  @type context :: %{
          optional(:remote_ip) => :inet.ip_address() | String.t() | nil,
          optional(:expected_hostname) => String.t() | nil,
          optional(:expected_action) => String.t() | nil
        }

  @callback verify(token :: String.t(), context()) :: :ok | {:error, atom()}
end
