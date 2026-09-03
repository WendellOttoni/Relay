defmodule Relay.Chat.Request do
  @moduledoc """Validates and normalizes the public `chat:generate` payload."""

  alias Relay.Chat.Message

  @default_limits %{max_messages: 20, max_message_bytes: 8_192, max_request_bytes: 65_536}

  @enforce_keys [:messages]
  defstruct [:messages]

  @type t :: %__MODULE__{messages: [Message.t()]}
  @type limits :: %{
          optional(:max_messages) => pos_integer(),
          optional(:max_message_bytes) => pos_integer(),
          optional(:max_request_bytes) => pos_integer()
        }

  @spec validate(term(), limits()) :: {:ok, t()} | {:error, :invalid_request}
  def validate(payload, limits \\ %{}) do
    limits = Map.merge(@default_limits, limits)

    with %{"messages" => messages} when map_size(payload) == 1 <- payload,
         true <- is_list(messages) and messages != [],
         true <- length(messages) <= limits.max_messages,
         {:ok, normalized, total_bytes} <- normalize_messages(messages, limits),
         true <- total_bytes <= limits.max_request_bytes do
      {:ok, %__MODULE__{messages: normalized}}
    else
      _ -> {:error, :invalid_request}
    end
  end

  defp normalize_messages(messages, limits) do
    Enum.reduce_while(messages, {:ok, [], 0}, fn
      %{"role" => role, "content" => content} = message, {:ok, acc, bytes}
      when map_size(message) == 2 and role in ["user", "assistant"] and is_binary(content) ->
        content_bytes = byte_size(content)

        if content != "" and content_bytes <= limits.max_message_bytes do
          normalized = %Message{role: String.to_existing_atom(role), content: content}
          {:cont, {:ok, [normalized | acc], bytes + content_bytes}}
        else
          {:halt, {:error, :invalid_request}}
        end

      _, _acc ->
        {:halt, {:error, :invalid_request}}
    end)
    |> case do
      {:ok, normalized, bytes} -> {:ok, Enum.reverse(normalized), bytes}
      error -> error
    end
  end
end
