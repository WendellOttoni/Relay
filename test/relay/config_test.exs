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

  test "rejects origins with user credentials or invalid ports" do
    assert {_, ["ALLOWED_ORIGINS entries must not contain user credentials"]} =
             Relay.Config.parse_origins("https://user@example.com", :prod)

    assert {_, ["ALLOWED_ORIGINS contains an invalid port"]} =
             Relay.Config.parse_origins("https://example.com:65536", :prod)
  end

  test "converts HTTP origins to Phoenix socket origins" do
    assert Relay.Config.websocket_origins(["https://example.com", "http://localhost:5173"]) ==
             ["//example.com", "//localhost:5173"]
  end

  test "parses runtime boolean switches strictly" do
    assert {true, []} = Relay.Config.parse_boolean("true", "CHAT_ENABLED", false)
    assert {false, []} = Relay.Config.parse_boolean(nil, "CHAT_ENABLED", false)

    assert {false, ["CHAT_ENABLED must be true or false"]} =
             Relay.Config.parse_boolean("yes", "CHAT_ENABLED", false)
  end

  test "parses positive integer runtime limits" do
    assert {1_000, []} =
             Relay.Config.parse_positive_integer(nil, "CHAT_MAX_OUTPUT_TOKENS", 1_000)

    assert {42, []} =
             Relay.Config.parse_positive_integer("42", "CHAT_MAX_OUTPUT_TOKENS", 1_000)

    assert {1, ["CHAT_MAX_OUTPUT_TOKENS must be a positive integer"]} =
             Relay.Config.parse_positive_integer("0", "CHAT_MAX_OUTPUT_TOKENS", 1_000)
  end

  test "parses deployment ports safely" do
    assert {4_000, []} = Relay.Config.parse_port(nil, 4_000)
    assert {10_000, []} = Relay.Config.parse_port("10000", 4_000)

    assert {4_000, ["PORT must be an integer between 1 and 65535"]} =
             Relay.Config.parse_port("not-a-port", 4_000)

    assert {4_000, ["PORT must be an integer between 1 and 65535"]} =
             Relay.Config.parse_port("65536", 4_000)
  end

  test "parses documented log levels strictly" do
    assert {:info, []} = Relay.Config.parse_log_level(nil, :info)
    assert {:debug, []} = Relay.Config.parse_log_level("debug", :info)

    assert {:info, ["LOG_LEVEL must be debug, info, warning, or error"]} =
             Relay.Config.parse_log_level("verbose", :info)
  end
end
