defmodule RelayWeb.ErrorController do
  use RelayWeb, :controller

  def not_found(conn, _params) do
    RelayWeb.ErrorResponse.send(conn, 404, "not_found", "Recurso não encontrado.")
  end
end
