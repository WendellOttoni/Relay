defmodule RelayWeb.Router do
  use RelayWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/health", RelayWeb do
    pipe_through :api

    get "/live", HealthController, :live
    get "/ready", HealthController, :ready
  end

  scope "/api/v1", RelayWeb do
    pipe_through :api

    post "/sessions", SessionController, :create
    post "/leads", LeadController, :create
  end

  scope "/", RelayWeb do
    pipe_through :api
    match :*, "/*path", ErrorController, :not_found
  end
end
