defmodule Relay.Integrations.OpenRouterTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Relay.Chat.Message
  alias Relay.Integrations.OpenRouter

  @base_options [api_key: "secret", model: "vendor/model", max_tokens: 100]

  test "implements the provider contract over Req's incremental callback" do
    chunks = [
      "data: {\"choices\":[{\"delta\":{\"content\":\"oi\"}}]}\n\n",
      "data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":2,\"completion_tokens\":1}}\n\n",
      "data: [DONE]\n\n"
    ]

    request_fun = successful_stream(chunks)
    owner = self()

    assert {:ok, :stop} =
             OpenRouter.stream(
               [%Message{role: :user, content: "olá"}],
               &send(owner, {:event, &1}),
               Keyword.put(@base_options, :request_fun, request_fun)
             )

    assert_receive {:event, {:delta, "oi"}}
    assert_receive {:event, {:usage, %{input_tokens: 2, output_tokens: 1}}}
  end

  test "maps HTTP failures and discards the raw response body" do
    owner = self()

    request_fun = fn request ->
      response = %Req.Response{status: 429}

      {:cont, {_request, response}} =
        request.into.({:data, "paid secret error"}, {request, response})

      send(owner, {:response_body, response.body})
      {:ok, response}
    end

    assert {:error, :rate_limited} =
             OpenRouter.stream(
               [%Message{role: :user, content: "olá"}],
               fn _ -> flunk("must not emit") end,
               Keyword.put(@base_options, :request_fun, request_fun)
             )

    assert_receive {:response_body, ""}
  end

  test "returns a safe failure for a stream that ends without DONE" do
    request_fun =
      successful_stream([
        "data: {\"choices\":[{\"delta\":{\"content\":\"partial\"}}]}\n\n"
      ])

    assert {:error, :truncated_stream} =
             OpenRouter.stream(
               [%Message{role: :user, content: "olá"}],
               fn _event -> :ok end,
               Keyword.put(@base_options, :request_fun, request_fun)
             )
  end

  test "logs a categorized, content-free completion event with the request/generation ids" do
    chunks = [
      "data: {\"choices\":[{\"delta\":{\"content\":\"SENTINEL-DO-NOT-LOG\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":2,\"completion_tokens\":1}}\n\n",
      "data: [DONE]\n\n"
    ]

    request_fun = successful_stream(chunks)

    options =
      @base_options
      |> Keyword.merge(
        api_key: "top-secret-key",
        request_id: "req-1",
        generation_id: "gen-1",
        request_fun: request_fun
      )

    log =
      capture_log([level: :info, metadata: :all], fn ->
        assert {:ok, :stop} =
                 OpenRouter.stream(
                   [%Message{role: :user, content: "olá"}],
                   fn _event -> :ok end,
                   options
                 )
      end)

    assert log =~ "open_router_generation_completed"
    assert log =~ "req-1"
    assert log =~ "gen-1"
    assert log =~ "vendor/model"
    assert log =~ "input_tokens=2"
    assert log =~ "output_tokens=1"
    assert log =~ "result=stop"
    refute log =~ "top-secret-key"
    refute log =~ "SENTINEL-DO-NOT-LOG"
  end

  test "logs a categorized failure without the raw provider error body" do
    request_fun = fn request ->
      response = %Req.Response{status: 429}

      {:cont, {_request, response}} =
        request.into.({:data, "paid secret error"}, {request, response})

      {:ok, response}
    end

    options =
      Keyword.merge(@base_options,
        api_key: "top-secret-key",
        request_id: "req-2",
        generation_id: "gen-2",
        request_fun: request_fun
      )

    log =
      capture_log([level: :info, metadata: :all], fn ->
        assert {:error, :rate_limited} =
                 OpenRouter.stream(
                   [%Message{role: :user, content: "olá"}],
                   fn _ -> :ok end,
                   options
                 )
      end)

    assert log =~ "result=rate_limited"
    refute log =~ "paid secret error"
    refute log =~ "top-secret-key"
  end

  defp successful_stream(chunks) do
    fn request ->
      response = %Req.Response{status: 200}

      {_request, response} =
        Enum.reduce_while(chunks, {request, response}, fn chunk, accumulator ->
          case request.into.({:data, chunk}, accumulator) do
            {:cont, next} -> {:cont, next}
            {:halt, next} -> {:halt, next}
          end
        end)

      {:ok, response}
    end
  end
end
