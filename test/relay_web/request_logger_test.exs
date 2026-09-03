defmodule RelayWeb.RequestLoggerTest do
  use RelayWeb.ConnCase, async: false

  import ExUnit.CaptureLog

  test "does not leak a known secret from request headers into structured logs", %{conn: conn} do
    log =
      capture_log([level: :info], fn ->
        conn
        |> put_req_header("authorization", "Bearer top-secret-value")
        |> get(~p"/health/live")
      end)

    assert log =~ "request_completed"
    refute log =~ "top-secret-value"
  end
end
