defmodule RelayWeb.LeadControllerTest do
  use RelayWeb.ConnCase, async: false

  defmodule FakeDelivery do
    @behaviour Relay.Leads.Delivery

    @impl true
    def deliver(lead, metadata, opts) do
      send(opts[:test_pid], {:delivered_lead, lead, metadata})
      :ok
    end
  end

  setup do
    keys = [:chat_allow_unprotected_demo, :lead_delivery, :lead_rate_limiter]
    previous = Map.new(keys, &{&1, Application.get_env(:relay, &1)})

    limiter =
      Module.concat(__MODULE__, String.to_atom("Limiter#{System.unique_integer([:positive])}"))

    start_supervised!(%{
      id: limiter,
      start: {Relay.Leads.RateLimiter, :start_link, [[name: limiter, limit: 10]]}
    })

    Application.put_env(:relay, :chat_allow_unprotected_demo, true)
    Application.put_env(:relay, :lead_delivery, {FakeDelivery, test_pid: self()})
    Application.put_env(:relay, :lead_rate_limiter, limiter)

    on_exit(fn ->
      Enum.each(previous, fn {key, value} ->
        if is_nil(value),
          do: Application.delete_env(:relay, key),
          else: Application.put_env(:relay, key, value)
      end)
    end)

    {:ok, session} = Relay.Sessions.create_session(%{network_key: make_ref()})
    {:ok, socket_token: session.socket_token}
  end

  test "delivers a validated lead from an authenticated session", %{
    conn: conn,
    socket_token: token
  } do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api/v1/leads", valid_params())

    assert %{"status" => "delivered"} = json_response(conn, 201)
    assert_receive {:delivered_lead, lead, _metadata}
    assert lead.email == "ana@example.com"
  end

  test "rejects unauthenticated and invalid submissions", %{conn: conn, socket_token: token} do
    assert %{"error" => %{"code" => "invalid_session"}} =
             conn |> post("/api/v1/leads", valid_params()) |> json_response(401)

    invalid = %{valid_params() | "consent" => false}

    assert %{"error" => %{"code" => "invalid_request"}} =
             conn
             |> recycle()
             |> put_req_header("authorization", "Bearer #{token}")
             |> post("/api/v1/leads", invalid)
             |> json_response(400)
  end

  defp valid_params do
    %{
      "name" => "Ana",
      "email" => "ana@example.com",
      "company" => "Empresa",
      "projectType" => "API e integração",
      "timeframe" => "2 meses",
      "budget" => "A definir",
      "summary" => "Integração entre dois sistemas existentes.",
      "proposal" => "Escopo inicial revisado pela visitante.",
      "consent" => true
    }
  end
end
