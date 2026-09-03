defmodule RelayWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint RelayWeb.Endpoint
      use RelayWeb, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
