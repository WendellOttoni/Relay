defmodule Relay.Leads.Request do
  @moduledoc "Validates and normalizes public lead submissions."

  alias Relay.Leads.Lead

  @allowed_keys ~w(name email company projectType timeframe budget summary proposal consent)
  @email_pattern ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/u

  @spec validate(term()) :: {:ok, Lead.t()} | {:error, :invalid_request}
  def validate(params) when is_map(params) do
    with true <- Enum.all?(Map.keys(params), &(&1 in @allowed_keys)),
         true <- params["consent"] == true,
         {:ok, name} <- required(params, "name", 120),
         {:ok, email} <- required(params, "email", 254),
         true <- Regex.match?(@email_pattern, email),
         {:ok, project_type} <- required(params, "projectType", 80),
         {:ok, summary} <- required(params, "summary", 4_000),
         {:ok, company} <- optional(params, "company", 160),
         {:ok, timeframe} <- optional(params, "timeframe", 120),
         {:ok, budget} <- optional(params, "budget", 120),
         {:ok, proposal} <- optional(params, "proposal", 8_000) do
      {:ok,
       %Lead{
         name: name,
         email: email,
         company: company,
         project_type: project_type,
         timeframe: timeframe,
         budget: budget,
         summary: summary,
         proposal: proposal
       }}
    else
      _ -> {:error, :invalid_request}
    end
  end

  def validate(_params), do: {:error, :invalid_request}

  defp required(params, key, max_bytes) do
    case params[key] do
      value when is_binary(value) ->
        value = String.trim(value)
        if value != "" and byte_size(value) <= max_bytes, do: {:ok, value}, else: :error

      _other ->
        :error
    end
  end

  defp optional(params, key, max_bytes) do
    case params[key] do
      nil ->
        {:ok, nil}

      "" ->
        {:ok, nil}

      value when is_binary(value) ->
        value = String.trim(value)
        if byte_size(value) <= max_bytes, do: {:ok, empty_to_nil(value)}, else: :error

      _other ->
        :error
    end
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(value), do: value
end
