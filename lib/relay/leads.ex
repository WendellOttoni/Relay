defmodule Relay.Leads do
  @moduledoc "Validates and delivers commercial opportunities."

  alias Relay.Leads.{RateLimiter, Request}

  @spec submit(map(), String.t(), map()) :: :ok | {:error, atom()}
  def submit(params, session_id, metadata) when is_binary(session_id) do
    with {:ok, lead} <- Request.validate(params),
         :ok <- RateLimiter.allow?(session_id, rate_limiter()),
         :ok <- deliver(lead, metadata) do
      :ok
    end
  end

  defp deliver(lead, metadata) do
    case Application.get_env(:relay, :lead_delivery, Relay.Leads.DisabledDelivery) do
      {module, opts} when is_atom(module) and is_list(opts) ->
        module.deliver(lead, metadata, opts)

      module when is_atom(module) ->
        module.deliver(lead, metadata, [])

      _invalid ->
        {:error, :unavailable}
    end
  end

  defp rate_limiter,
    do: Application.get_env(:relay, :lead_rate_limiter, Relay.Leads.RateLimiter)
end
