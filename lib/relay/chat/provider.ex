defmodule Relay.Chat.Provider do
  @moduledoc """
  Provider boundary for incremental chat generation.

  Implementations emit normalized events and return a terminal result. They do
  not know about Phoenix sockets or the public wire protocol.
  """

  alias Relay.Chat.Message

  @type event ::
          {:delta, String.t()}
          | {:usage, %{optional(:input_tokens) => non_neg_integer(), optional(:output_tokens) => non_neg_integer()}}

  @type finish_reason :: :stop | :length
  @type error_reason :: :unavailable | :timeout | :rate_limited | term()
  @type emitter :: (event() -> any())

  @callback stream([Message.t()], emitter(), keyword()) ::
              {:ok, finish_reason()} | {:error, error_reason()}
end
