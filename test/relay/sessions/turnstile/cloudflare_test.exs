defmodule Relay.Sessions.Turnstile.CloudflareTest do
  use ExUnit.Case, async: false

  alias Relay.Sessions.Turnstile.Cloudflare

  setup do
    keys = [
      :turnstile_secret_key,
      :turnstile_request,
      :turnstile_siteverify_url,
      :turnstile_expected_hostname,
      :turnstile_expected_action
    ]

    previous = Map.new(keys, &{&1, Application.get_env(:relay, &1)})

    Application.put_env(:relay, :turnstile_secret_key, "test-secret")

    on_exit(fn ->
      Enum.each(previous, fn {key, value} ->
        if is_nil(value),
          do: Application.delete_env(:relay, key),
          else: Application.put_env(:relay, key, value)
      end)
    end)

    :ok
  end

  test "posts the token and remote IP to Siteverify and accepts matching claims" do
    Application.put_env(:relay, :turnstile_expected_hostname, "relay.example")
    Application.put_env(:relay, :turnstile_expected_action, "chat")

    Application.put_env(:relay, :turnstile_request, fn request ->
      send(self(), {:siteverify_request, request})

      {:ok,
       %{
         status: 200,
         body: %{"success" => true, "hostname" => "relay.example", "action" => "chat"}
       }}
    end)

    assert :ok =
             Cloudflare.verify("response-token", %{
               remote_ip: {203, 0, 113, 9},
               expected_hostname: "relay.example",
               expected_action: "chat"
             })

    assert_receive {:siteverify_request, request}
    assert request.url == "https://challenges.cloudflare.com/turnstile/v0/siteverify"

    assert request.form == [
             remoteip: "203.0.113.9",
             secret: "test-secret",
             response: "response-token"
           ]
  end

  test "rejects an otherwise successful response for a different hostname or action" do
    Application.put_env(:relay, :turnstile_request, fn _request ->
      {:ok,
       %{
         status: 200,
         body: %{"success" => true, "hostname" => "other.example", "action" => "other"}
       }}
    end)

    assert {:error, :invalid_challenge} =
             Cloudflare.verify("response-token", %{
               expected_hostname: "relay.example",
               expected_action: "chat"
             })
  end

  test "fails closed when Siteverify rejects the token, cannot be reached, or no secret exists" do
    Application.put_env(:relay, :turnstile_request, fn _request ->
      {:ok, %{status: 200, body: %{"success" => false}}}
    end)

    assert {:error, :invalid_challenge} = Cloudflare.verify("response-token", %{})

    Application.put_env(:relay, :turnstile_request, fn _request -> {:error, :timeout} end)
    assert {:error, :validator_unavailable} = Cloudflare.verify("response-token", %{})

    Application.delete_env(:relay, :turnstile_secret_key)
    assert {:error, :validator_unavailable} = Cloudflare.verify("response-token", %{})
  end
end
