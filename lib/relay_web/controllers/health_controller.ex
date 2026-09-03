defmodule RelayWeb.HealthController do
  use RelayWeb, :controller

  def live(conn, _params) do
    json(conn, %{status: "ok"})
  end

  def ready(conn, _params) do
    if Relay.Config.ready?() do
      json(conn, %{status: "ready"})
    else
      RelayWeb.ErrorResponse.send(
        conn,
        503,
        "not_ready",
        "Serviço ainda não está pronto."
      )
    end
  end
end
