defmodule Relay.Integrations.FormspreeTest do
  use ExUnit.Case, async: true

  alias Relay.Integrations.Formspree
  alias Relay.Leads.Lead

  test "posts only validated lead fields to the configured HTTPS form" do
    lead = %Lead{
      name: "Ana",
      email: "ana@example.com",
      project_type: "API",
      summary: "Integração entre sistemas",
      company: nil,
      timeframe: "2 meses",
      budget: "A definir",
      proposal: "Escopo preliminar"
    }

    request_fun = fn request ->
      send(self(), {:formspree_request, request})
      {:ok, %Req.Response{status: 200}}
    end

    assert :ok =
             Formspree.deliver(lead, %{request_id: "request-id"},
               endpoint: "https://formspree.io/f/example123",
               request_fun: request_fun
             )

    assert_receive {:formspree_request, request}
    assert request.method == :post
    assert URI.to_string(request.url) == "https://formspree.io/f/example123"
    assert Req.Request.get_header(request, "accept") == ["application/json"]
    assert request.options[:json]["email"] == "ana@example.com"
    assert request.options[:json]["relayRequestId"] == "request-id"
  end

  test "rejects non-Formspree endpoints and hides provider failures" do
    lead = %Lead{name: "Ana", email: "ana@example.com", project_type: "API", summary: "Projeto"}

    assert {:error, :unavailable} =
             Formspree.deliver(lead, %{}, endpoint: "https://attacker.example/collect")

    refute Formspree.valid_endpoint?("http://formspree.io/f/example123")
    refute Formspree.valid_endpoint?("https://formspree.io/f/example123/extra")
    assert Formspree.valid_endpoint?("https://formspree.io/f/example123")

    assert {:error, :unavailable} =
             Formspree.deliver(lead, %{},
               endpoint: "https://formspree.io/f/example123",
               request_fun: fn _request -> {:ok, %Req.Response{status: 500}} end
             )
  end
end
