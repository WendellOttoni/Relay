defmodule Relay.Integrations.OpenRouter do
  @moduledoc """
  Streaming OpenRouter adapter for `Relay.Chat.Provider`.

  It translates the provider protocol at the boundary and deliberately discards
  non-success response bodies. Provider response text is never returned or logged.

  Every call logs a single structured, content-free completion event so calls
  can be observed without ever storing prompt or credential material. The
  caller may pass `:request_id` and `:generation_id` in `opts` to correlate
  that event with the originating Channel exchange.
  """

  @behaviour Relay.Chat.Provider

  require Logger

  alias Relay.Integrations.OpenRouter.{Request, SSEParser}

  @parser_private_key :relay_open_router_parser
  @outcome_private_key :relay_open_router_outcome
  @usage_private_key :relay_open_router_usage

  @impl true
  def stream(messages, emit, opts) when is_function(emit, 1) and is_list(opts) do
    started_at = System.monotonic_time()
    {result, usage} = do_stream(messages, emit, opts)
    log_generation(opts, started_at, result, usage)
    emit_generation_telemetry(started_at, result, usage)
    result
  end

  def stream(_messages, _emit, _opts), do: {:error, :unavailable}

  defp do_stream(messages, emit, opts) do
    with {:ok, request} <- Request.build(messages, opts) do
      request =
        Req.merge(request,
          into: stream_callback(emit),
          receive_timeout: Keyword.get(opts, :receive_timeout, 15_000),
          request_timeout: Keyword.get(opts, :request_timeout, 90_000),
          connect_options: [timeout: Keyword.get(opts, :connect_timeout, 10_000)]
        )

      request_fun = Keyword.get(opts, :request_fun, &Req.request/1)
      raw_result = request_fun.(request)
      {normalize_response(raw_result), usage_from(raw_result)}
    else
      {:error, :invalid_configuration} -> {{:error, :unavailable}, nil}
    end
  rescue
    _exception -> {{:error, :unavailable}, nil}
  catch
    :exit, _reason -> {{:error, :unavailable}, nil}
  end

  defp stream_callback(emit) do
    fn {:data, chunk}, {request, response} ->
      if response.status in 200..299 do
        parser = Req.Response.get_private(response, @parser_private_key, SSEParser.new())

        case SSEParser.feed(parser, chunk) do
          {:ok, parser, events} ->
            emit_events(events, emit)

            response =
              response
              |> Req.Response.put_private(@parser_private_key, parser)
              |> put_usage_private(events)

            {:cont, {request, response}}

          {:done, parser, events} ->
            emit_events(events, emit)

            response =
              response
              |> Req.Response.put_private(@parser_private_key, parser)
              |> Req.Response.put_private(@outcome_private_key, SSEParser.finish(parser))
              |> put_usage_private(events)

            {:halt, {request, response}}

          {:error, reason, parser, events} ->
            emit_events(events, emit)

            response =
              response
              |> Req.Response.put_private(@parser_private_key, parser)
              |> Req.Response.put_private(@outcome_private_key, {:error, reason})
              |> put_usage_private(events)

            {:halt, {request, response}}
        end
      else
        # Returning the accumulator unchanged makes Req discard the raw error body.
        {:cont, {request, response}}
      end
    end
  end

  defp emit_events(events, emit), do: Enum.each(events, emit)

  defp put_usage_private(response, events) do
    case Enum.find(events, &match?({:usage, _}, &1)) do
      {:usage, usage} -> Req.Response.put_private(response, @usage_private_key, usage)
      nil -> response
    end
  end

  defp usage_from({:ok, %Req.Response{} = response}),
    do: Req.Response.get_private(response, @usage_private_key)

  defp usage_from(_other), do: nil

  defp normalize_response({:ok, %Req.Response{status: status} = response})
       when status in 200..299 do
    case Req.Response.get_private(response, @outcome_private_key) do
      nil ->
        response
        |> Req.Response.get_private(@parser_private_key, SSEParser.new())
        |> SSEParser.finish()
        |> normalize_parser_result()

      result ->
        normalize_parser_result(result)
    end
  end

  defp normalize_response({:ok, %Req.Response{status: 429}}), do: {:error, :rate_limited}

  defp normalize_response({:ok, %Req.Response{status: status}})
       when status in [401, 402] or status in 500..599,
       do: {:error, :unavailable}

  defp normalize_response({:ok, %Req.Response{}}), do: {:error, :unavailable}

  defp normalize_response({:error, exception}) do
    if timeout_exception?(exception), do: {:error, :timeout}, else: {:error, :unavailable}
  end

  defp normalize_response(_other), do: {:error, :unavailable}

  defp normalize_parser_result({:ok, reason}) when reason in [:stop, :length], do: {:ok, reason}
  defp normalize_parser_result({:error, reason}), do: {:error, reason}

  defp timeout_exception?(%Req.TransportError{reason: reason}),
    do: reason in [:timeout, :connect_timeout, :checkout_timeout]

  defp timeout_exception?(%{reason: reason}), do: reason in [:timeout, :connect_timeout]
  defp timeout_exception?(_), do: false

  # Logs only identifiers, the configured model, timing and a categorized
  # outcome. `opts` as a whole is never inspected or logged: it also carries
  # the API key and the server-controlled system prompt.
  defp log_generation(opts, started_at, result, usage) do
    duration_ms =
      System.convert_time_unit(System.monotonic_time() - started_at, :native, :millisecond)

    Logger.info("open_router_generation_completed",
      request_id: Keyword.get(opts, :request_id),
      generation_id: Keyword.get(opts, :generation_id),
      model: Keyword.get(opts, :model),
      duration_ms: duration_ms,
      result: outcome_category(result),
      input_tokens: usage && Map.get(usage, :input_tokens),
      output_tokens: usage && Map.get(usage, :output_tokens)
    )
  end

  defp outcome_category({:ok, reason}), do: reason
  defp outcome_category({:error, reason}) when is_atom(reason), do: reason
  defp outcome_category({:error, _reason}), do: :unavailable

  defp emit_generation_telemetry(started_at, result, usage) do
    duration_ms =
      System.convert_time_unit(System.monotonic_time() - started_at, :native, :millisecond)

    :telemetry.execute(
      [:relay, :chat, :generation, :stop],
      %{
        duration_ms: duration_ms,
        input_tokens: (usage && Map.get(usage, :input_tokens)) || 0,
        output_tokens: (usage && Map.get(usage, :output_tokens)) || 0
      },
      %{outcome: outcome_category(result)}
    )
  end
end
