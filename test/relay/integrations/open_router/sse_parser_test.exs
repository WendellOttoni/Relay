defmodule Relay.Integrations.OpenRouter.SSEParserTest do
  use ExUnit.Case, async: true

  alias Relay.Integrations.OpenRouter.SSEParser

  test "parses deltas, usage, finish reason and DONE across arbitrary chunks" do
    stream =
      ": keepalive\r\n\r\n" <>
        "data: {\"choices\":[{\"delta\":{\"content\":\"Olá\"},\"finish_reason\":null}]}\r\n\r\n" <>
        "data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"length\"}],\"usage\":{\"prompt_tokens\":7,\"completion_tokens\":9}}\n\n" <>
        "data: [DONE]\n\n"

    chunks = for <<chunk::binary-size(1) <- stream>>, do: chunk

    assert {:done, parser, events} = feed_all(chunks)
    assert events == [{:delta, "Olá"}, {:usage, %{input_tokens: 7, output_tokens: 9}}]
    assert SSEParser.finish(parser) == {:ok, :length}
  end

  test "supports multiple data lines and ignores unknown SSE fields" do
    chunks = [
      "event: message\nid: 42\ndata: {\"choices\":\n",
      "data: [{\"delta\":{\"content\":\"x\"},\"finish_reason\":\"stop\"}]}\n\n",
      "data: [DONE]\n\n"
    ]

    assert {:done, parser, [{:delta, "x"}]} = feed_all(chunks)
    assert SSEParser.finish(parser) == {:ok, :stop}
  end

  test "rejects malformed and truncated streams without returning their body" do
    assert {:error, :unavailable, _parser, []} =
             SSEParser.feed(SSEParser.new(), "data: not-json\n\n")

    assert {:ok, parser, [{:delta, "partial"}]} =
             SSEParser.feed(
               SSEParser.new(),
               "data: {\"choices\":[{\"delta\":{\"content\":\"partial\"}}]}\n\n"
             )

    assert SSEParser.finish(parser) == {:error, :truncated_stream}
  end

  test "normalizes provider error objects to safe categories" do
    assert {:error, :rate_limited, _parser, []} =
             SSEParser.feed(
               SSEParser.new(),
               "data: {\"error\":{\"code\":429,\"message\":\"sensitive body\"}}\n\n"
             )

    assert {:error, :unavailable, _parser, []} =
             SSEParser.feed(
               SSEParser.new(),
               "data: {\"error\":{\"code\":401,\"message\":\"sensitive body\"}}\n\n"
             )
  end

  defp feed_all(chunks) do
    Enum.reduce_while(chunks, {:ok, SSEParser.new(), []}, fn chunk, {:ok, parser, events} ->
      case SSEParser.feed(parser, chunk) do
        {:ok, parser, new_events} ->
          {:cont, {:ok, parser, events ++ new_events}}

        {:done, parser, new_events} ->
          {:halt, {:done, parser, events ++ new_events}}

        {:error, reason, parser, new_events} ->
          {:halt, {:error, reason, parser, events ++ new_events}}
      end
    end)
  end
end