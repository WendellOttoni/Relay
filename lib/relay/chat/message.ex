defmodule Relay.Chat.Message do
  @moduledoc """
  A provider-independent chat message.

  Only roles that can originate in the public client are represented here. System
  messages belong to provider adapters and must never be accepted from the socket.
  """

  @enforce_keys [:role, :content]
  defstruct [:role, :content]

  @type role :: :user | :assistant
  @type t :: %__MODULE__{role: role(), content: String.t()}
end
