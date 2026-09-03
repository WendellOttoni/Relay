defmodule RelayWeb.UserSocket do
  use Phoenix.Socket

  channel "chat:*", RelayWeb.ChatChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case Relay.Sessions.verify_socket_token(token) do
      {:ok, %{session_id: session_id, expires_at: expires_at}} when is_binary(session_id) ->
        {:ok, assign(socket, session_id: session_id, session_expires_at: expires_at)}

      _error ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(%{assigns: %{session_id: session_id}}), do: "session:#{session_id}"
  def id(_socket), do: nil
end
