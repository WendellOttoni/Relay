defmodule Relay.ConfigTest do
  use ExUnit.Case, async: true

  test "accepts an explicit local HTTP origin" do
    assert {[
              "http://localhost:5173"
            ], []} = Relay.Config.parse_origins("http://localhost:5173", :dev)
  end

  test "production requires HTTPS and rejects localhost" do
    assert {_, errors} = Relay.Config.parse_origins("http://localhost:5173", :prod)
    assert "ALLOWED_ORIGINS must use HTTPS in production" in errors

    assert {_, errors} = Relay.Config.parse_origins("https://localhost", :prod)
    assert "ALLOWED_ORIGINS cannot contain localhost in production" in errors
  end

  test "rejects wildcard, null and URL paths" do
    assert {_, [_]} = Relay.Config.parse_origins("*", :dev)
    assert {_, [_]} = Relay.Config.parse_origins("null", :dev)
    assert {_, [_]} = Relay.Config.parse_origins("https://example.com/path", :dev)
  end

  test "converts HTTP origins to Phoenix socket origins" do
    assert Relay.Config.websocket_origins(["https://example.com", "http://localhost:5173"]) ==
             ["//example.com", "//localhost:5173"]
  end
end
