defmodule Relay.Leads.Delivery do
  @moduledoc "Boundary for delivering a validated commercial opportunity."

  alias Relay.Leads.Lead

  @callback deliver(Lead.t(), map(), keyword()) :: :ok | {:error, term()}
end
