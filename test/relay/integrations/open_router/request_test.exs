defmodule Relay.Integrations.OpenRouter.RequestTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.Message
  alias Relay.Integrations.OpenRouter.Request

  test "maps only internal messages and server-controlled options" do
    messages = [
      %Message{role: :user, content: "pergunta"},
      %Message{role: :assistant, content: "resposta anterior"}
    ]

    assert {:ok, request} =
             Request.build(messages,
               api_key: "test-secret",
               model: "vendor/model",
               system_prompt: "instrução",
               public_site_url: "https://example.github.io",
               max_tokens: 321
             )

    assert request.method == :post
    assert URI.to_string(request.url) == "https://openrouter.ai/api/v1/chat/completions"
    assert Req.Request.get_header(request, "authorization") == ["Bearer test-secret"]
    assert Req.Request.get_header(request, "accept") == ["text/event-stream"]
    assert Req.Request.get_header(request, "http-referer") == ["https://example.github.io"]
    assert Req.Request.get_header(request, "x-title") == ["Relay"]

    assert request.options[:json] == %{
             "model" => "vendor/model",
             "messages" => [
               %{"role" => "system", "content" => "instrução"},
               %{"role" => "user", "content" => "pergunta"},
               %{"role" => "assistant", "content" => "resposta anterior"}
             ],
             "stream" => true,
             "stream_options" => %{"include_usage" => true},
             "max_tokens" => 321
           }

    assert request.options[:redirect] == false
    assert request.options[:retry] == false
  end

  test "rejects missing configuration and messages outside the internal type" do
    message = %Message{role: :user, content: "ok"}

    assert {:error, :invalid_configuration} =
             Request.build([message], model: "model", max_tokens: 1)

    assert {:error, :invalid_configuration} =
             Request.build([%{role: :system, content: "injetado"}],
               api_key: "key",
               model: "model",
               max_tokens: 1
             )
  end
end