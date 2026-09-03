defmodule RelayWeb.CORSTest do
  use RelayWeb.ConnCase, async: false

  setup do
    previous = Application.get_env(:relay, :allowed_origins)
    Application.put_env(:relay, :allowed_origins, ["https://wendellottoni.github.io"])
    on_exit(fn -> Application.put_env(:relay, :allowed_origins, previous) end)
  end

  test "authorizes a configured origin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://wendellottoni.github.io")
      |> get(~p"/health/live")

    assert get_resp_header(conn, "access-control-allow-origin") ==
             ["https://wendellottoni.github.io"]
  end

  test "completes an allowed preflight", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://wendellottoni.github.io")
      |> put_req_header("access-control-request-method", "POST")
      |> options("/api/v1/sessions")

    assert conn.status == 204
  end

  test "rejects a preflight that asks for a method or header outside the API contract", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header("origin", "https://wendellottoni.github.io")
      |> put_req_header("access-control-request-method", "DELETE")
      |> options("/api/v1/sessions")

    assert %{"error" => %{"code" => "preflight_rejected"}} = json_response(conn, 403)

    conn =
      build_conn()
      |> put_req_header("origin", "https://wendellottoni.github.io")
      |> put_req_header("access-control-request-method", "POST")
      |> put_req_header("access-control-request-headers", "content-type, authorization")
      |> options("/api/v1/sessions")

    assert %{"error" => %{"code" => "preflight_rejected"}} = json_response(conn, 403)
  end

  test "does not authorize an unexpected origin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://attacker.example")
      |> get(~p"/health/live")

    assert get_resp_header(conn, "access-control-allow-origin") == []
  end

  test "rejects preflight from an unexpected origin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://attacker.example")
      |> options("/api/v1/sessions")

    assert %{"error" => %{"code" => "origin_forbidden"}} = json_response(conn, 403)
  end

  test "rejects a WebSocket handshake from an unexpected origin", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://attacker.example")
      |> get("/socket/websocket?vsn=2.0.0")

    assert conn.status == 403
  end
end
