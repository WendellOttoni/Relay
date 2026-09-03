defmodule RelayWeb.HealthControllerTest do
  use RelayWeb.ConnCase, async: false

  setup do
    previous = Application.get_env(:relay, :runtime_config_errors)

    on_exit(fn ->
      Application.put_env(:relay, :runtime_config_errors, previous)
    end)
  end

  test "liveness only reports that the process is serving", %{conn: conn} do
    conn = get(conn, ~p"/health/live")

    assert %{"status" => "ok"} = json_response(conn, 200)
    assert [request_id] = get_resp_header(conn, "x-request-id")
    assert byte_size(request_id) > 0
  end

  test "readiness succeeds with valid runtime configuration", %{conn: conn} do
    Application.put_env(:relay, :runtime_config_errors, [])

    conn = get(conn, ~p"/health/ready")
    assert %{"status" => "ready"} = json_response(conn, 200)
  end

  test "readiness returns a safe error when configuration is invalid", %{conn: conn} do
    Application.put_env(:relay, :runtime_config_errors, ["SECRET_KEY_BASE is missing"])

    conn = get(conn, ~p"/health/ready")

    assert %{
             "error" => %{
               "code" => "not_ready",
               "message" => "Serviço ainda não está pronto.",
               "requestId" => request_id
             }
           } = json_response(conn, 503)

    assert request_id in get_resp_header(conn, "x-request-id")
    refute conn.resp_body =~ "SECRET_KEY_BASE"
  end
end
