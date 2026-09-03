defmodule RelayWeb.ErrorJSONTest do
  use ExUnit.Case, async: true

  test "renders a safe body for the mapped status codes" do
    for {template, code} <- [
          {"400.json", "invalid_request"},
          {"403.json", "forbidden"},
          {"404.json", "not_found"},
          {"413.json", "payload_too_large"},
          {"429.json", "rate_limit_exceeded"},
          {"503.json", "service_unavailable"}
        ] do
      assert %{error: %{code: ^code, message: message}} = RelayWeb.ErrorJSON.render(template, %{})
      assert is_binary(message)
    end
  end

  test "renders a safe fallback for an unmapped/unhandled error" do
    assert %{error: %{code: "internal_error", message: message}} =
             RelayWeb.ErrorJSON.render("500.json", %{})

    assert message == "Falha interna."
  end

  test "does not leak stacktrace or exception details" do
    body = RelayWeb.ErrorJSON.render("500.json", %{reason: %RuntimeError{message: "top secret"}})

    refute inspect(body) =~ "top secret"
  end

  test "includes the request ID currently tracked by the process" do
    Process.put(:relay_request_id, "relay-error-json-test")
    on_exit(fn -> Process.delete(:relay_request_id) end)

    assert %{error: %{requestId: "relay-error-json-test"}} =
             RelayWeb.ErrorJSON.render("500.json", %{})
  end
end
