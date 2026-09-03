defmodule RelayWeb.ErrorContractTest do
  use RelayWeb.ConnCase, async: true

  test "unknown routes use the common safe error contract", %{conn: conn} do
    conn = get(conn, "/does-not-exist")

    assert %{
             "error" => %{
               "code" => "not_found",
               "message" => "Recurso não encontrado.",
               "requestId" => request_id
             }
           } = json_response(conn, 404)

    assert request_id in get_resp_header(conn, "x-request-id")
  end

  test "propagates a valid request ID", %{conn: conn} do
    conn =
      conn |> put_req_header("x-request-id", "relay-test-request-id") |> get(~p"/health/live")

    assert get_resp_header(conn, "x-request-id") == ["relay-test-request-id"]
  end

  test "rejects a body above the configured length limit", %{conn: conn} do
    oversized_body = String.duplicate("a", 70_000)

    {413, headers, body} =
      assert_error_sent 413, fn ->
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/health/live", oversized_body)
      end

    assert {_, "application/json" <> _} = List.keyfind(headers, "content-type", 0)
    assert %{"error" => %{"code" => "payload_too_large"}} = Jason.decode!(body)
  end
end
