defmodule Relay.Chat.RequestTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.{Message, Request}

  test "normalizes a valid public payload" do
    assert {:ok,
            %Request{
              messages: [
                %Message{role: :user, content: "Olá"},
                %Message{role: :assistant, content: "Oi"}
              ]
            }} =
             Request.validate(%{
               "messages" => [
                 %{"role" => "user", "content" => "Olá"},
                 %{"role" => "assistant", "content" => "Oi"}
               ]
             })
  end

  test "rejects unknown fields and system messages" do
    assert {:error, :invalid_request} =
             Request.validate(%{
               "messages" => [%{"role" => "user", "content" => "Olá", "extra" => true}]
             })

    assert {:error, :invalid_request} =
             Request.validate(%{
               "messages" => [%{"role" => "system", "content" => "segredo"}]
             })

    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [], "extra" => true})
  end

  test "rejects empty and incorrectly typed content" do
    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [%{"role" => "user", "content" => ""}]})

    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [%{"role" => "user", "content" => 123}]})
  end

  test "enforces message count, per-message bytes and total bytes at boundaries" do
    message = fn content -> %{"role" => "user", "content" => content} end

    assert {:ok, _request} =
             Request.validate(%{"messages" => [message.("1234"), message.("5678")]}, %{
               max_messages: 2,
               max_message_bytes: 4,
               max_request_bytes: 8
             })

    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [message.("12345")]}, %{max_message_bytes: 4})

    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [message.("1234"), message.("56789")]}, %{
               max_request_bytes: 8
             })

    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [message.("1"), message.("2"), message.("3")]}, %{
               max_messages: 2
             })
  end

  test "counts UTF-8 bytes rather than graphemes" do
    assert {:error, :invalid_request} =
             Request.validate(%{"messages" => [%{"role" => "user", "content" => "á"}]}, %{
               max_message_bytes: 1
             })
  end
end
