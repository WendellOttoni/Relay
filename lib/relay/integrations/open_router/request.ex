defmodule Relay.Integrations.OpenRouter.Request do
  @moduledoc false

  alias Relay.Chat.Message

  @endpoint "https://openrouter.ai/api/v1/chat/completions"

  @spec build([Message.t()], keyword()) ::
          {:ok, Req.Request.t()} | {:error, :invalid_configuration}
  def build(messages, opts) when is_list(messages) and is_list(opts) do
    with {:ok, api_key} <- required_binary(opts, :api_key),
         {:ok, model} <- required_binary(opts, :model),
         {:ok, max_tokens} <- positive_integer(opts, :max_tokens),
         {:ok, mapped_messages} <- map_messages(messages),
         {:ok, system_prompt} <- optional_binary(opts, :system_prompt),
         {:ok, site_url} <- optional_binary(opts, :public_site_url) do
      payload = %{
        "model" => model,
        "messages" => prepend_system_message(mapped_messages, system_prompt),
        "stream" => true,
        "stream_options" => %{"include_usage" => true},
        "max_tokens" => max_tokens
      }

      headers =
        [
          {"authorization", "Bearer " <> api_key},
          {"accept", "text/event-stream"},
          {"content-type", "application/json"},
          {"x-title", "Relay"}
        ]
        |> maybe_add_referer(site_url)

      request =
        Req.new(
          method: :post,
          url: @endpoint,
          headers: headers,
          json: payload,
          redirect: false,
          retry: false
        )

      {:ok, request}
    else
      _ -> {:error, :invalid_configuration}
    end
  end

  def build(_messages, _opts), do: {:error, :invalid_configuration}

  defp map_messages(messages) do
    Enum.reduce_while(messages, {:ok, []}, fn
      %Message{role: role, content: content}, {:ok, acc}
      when role in [:user, :assistant] and is_binary(content) and content != "" ->
        {:cont, {:ok, [%{"role" => Atom.to_string(role), "content" => content} | acc]}}

      _message, _acc ->
        {:halt, {:error, :invalid_message}}
    end)
    |> case do
      {:ok, mapped} -> {:ok, Enum.reverse(mapped)}
      error -> error
    end
  end

  defp prepend_system_message(messages, nil), do: messages

  defp prepend_system_message(messages, prompt),
    do: [%{"role" => "system", "content" => prompt} | messages]

  defp required_binary(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, key}
    end
  end

  defp optional_binary(opts, key) do
    case Keyword.get(opts, key) do
      nil -> {:ok, nil}
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, key}
    end
  end

  defp positive_integer(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) and value > 0 -> {:ok, value}
      _ -> {:error, key}
    end
  end

  defp maybe_add_referer(headers, nil), do: headers
  defp maybe_add_referer(headers, value), do: [{"http-referer", value} | headers]
end
