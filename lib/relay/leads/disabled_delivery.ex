defmodule Relay.Leads.DisabledDelivery do
  @moduledoc false
  @behaviour Relay.Leads.Delivery

  @impl true
  def deliver(_lead, _metadata, _opts), do: {:error, :unavailable}
end
