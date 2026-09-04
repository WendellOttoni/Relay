defmodule Relay.Integrations.Formspree do
  @moduledoc "Delivers validated opportunities to a configured Formspree form."

  @behaviour Relay.Leads.Delivery

  alias Relay.Leads.Lead

  @impl true
  def deliver(%Lead{} = lead, metadata, opts) when is_list(opts) do
    with {:ok, endpoint} <- endpoint(opts),
         {:ok, %Req.Response{status: status}} when status in 200..299 <-
           request_fun(opts).(
             Req.new(
               method: :post,
               url: endpoint,
               headers: [{"accept", "application/json"}],
               json: payload(lead, metadata),
               redirect: false,
               retry: false,
               connect_options: [timeout: 10_000],
               receive_timeout: 15_000
             )
           ) do
      :ok
    else
      _error -> {:error, :unavailable}
    end
  rescue
    _exception -> {:error, :unavailable}
  catch
    :exit, _reason -> {:error, :unavailable}
  end

  def deliver(_lead, _metadata, _opts), do: {:error, :unavailable}

  @spec valid_endpoint?(term()) :: boolean()
  def valid_endpoint?(value), do: match?({:ok, _endpoint}, endpoint(endpoint: value))

  defp endpoint(opts) do
    with value when is_binary(value) <- Keyword.get(opts, :endpoint),
         %URI{
           scheme: "https",
           host: "formspree.io",
           port: 443,
           path: path,
           query: nil,
           fragment: nil,
           userinfo: nil
         } <- URI.parse(value),
         ["f", form_id] when form_id != "" <- String.split(path, "/", trim: true) do
      {:ok, value}
    else
      _other -> {:error, :invalid_configuration}
    end
  end

  defp request_fun(opts), do: Keyword.get(opts, :request_fun, &Req.request/1)

  defp payload(lead, metadata) do
    %{
      "_subject" => "Nova oportunidade recebida pelo Relay",
      "name" => lead.name,
      "email" => lead.email,
      "company" => lead.company,
      "projectType" => lead.project_type,
      "timeframe" => lead.timeframe,
      "budget" => lead.budget,
      "summary" => lead.summary,
      "proposal" => lead.proposal,
      "relayRequestId" => metadata[:request_id]
    }
  end
end
