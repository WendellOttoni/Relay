defmodule Relay.Leads.RequestTest do
  use ExUnit.Case, async: true

  alias Relay.Leads.Request

  test "accepts a consented and bounded opportunity" do
    assert {:ok, lead} = Request.validate(valid_params())
    assert lead.name == "Ana"
    assert lead.email == "ana@example.com"
    assert lead.company == nil
    assert lead.project_type == "Modernização de sistema"
  end

  test "rejects missing consent, invalid email, oversized data and unknown fields" do
    assert {:error, :invalid_request} = Request.validate(%{valid_params() | "consent" => false})
    assert {:error, :invalid_request} = Request.validate(%{valid_params() | "email" => "invalid"})

    assert {:error, :invalid_request} =
             Request.validate(%{valid_params() | "summary" => String.duplicate("a", 4_001)})

    assert {:error, :invalid_request} = Request.validate(Map.put(valid_params(), "admin", true))
  end

  defp valid_params do
    %{
      "name" => " Ana ",
      "email" => "ana@example.com",
      "company" => "",
      "projectType" => "Modernização de sistema",
      "timeframe" => "3 meses",
      "budget" => "A definir",
      "summary" => "Modernizar uma aplicação existente.",
      "proposal" => "Proposta preliminar revisada.",
      "consent" => true
    }
  end
end
