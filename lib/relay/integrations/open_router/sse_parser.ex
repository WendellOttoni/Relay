defmodule Relay.Integrations.OpenRouter.SSEParser do
  @moduledoc """
  Incremental, bounded-by-one-event parser for OpenRouter's SSE response.

  Transport chunks and SSE lines may end at arbitrary byte positions. The parser
  retains only the unfinished line and the current event, never the response.
  """

  @max_event_bytes 262_144

  defstruct buffer: <<>>,
            data_lines: [],
            event_bytes: 0,
            finish_reason: nil,
            done?: false

  @type event :: Relay.Chat.Provider.event()
  @type result ::
          {:ok, t(), [event()]}
          | {:done, t(), [event()]}
          | {:error, Relay.Chat.Provider.error_reason(), t(), [event()]}
  @type t :: %__MODULE__{
          buffer: binary(),
          data_lines: [binary()],
          event_bytes: non_neg_integer(),
          finish_reason: nil | :stop | :length,
          done?: boolean()
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec feed(t(), binary()) :: result()
  def feed(%__MODULE__{done?: true} = state, _chunk), do: {:done, state, []}

  def feed(%__MODULE__{} = state, chunk) when is_binary(chunk) do
    consume_lines(%{state | buffer: state.buffer <> chunk}, [])
  end

  @spec finish(t()) :: {:ok, :stop | :length} | {:error, :truncated_stream}
  def finish(%__MODULE__{done?: true, finish_reason: reason}), do: {:ok, reason || :stop}
  def finish(%__MODULE__{}), do: {:error, :truncated_stream}

  defp consume_lines(state, events) do
    case :binary.match(state.buffer, "\n") do
      :nomatch ->
        if byte_size(state.buffer) + state.event_bytes > @max_event_bytes do
          {:error, :unavailable, %{state | buffer: <<>>, data_lines: [], event_bytes: 0},
           Enum.reverse(events)}
        else
          {:ok, state, Enum.reverse(events)}
        end

      {index, 1} ->
        <<line::binary-size(^index), _newline, rest::binary>> = state.buffer
        line = trim_carriage_return(line)

        case consume_line(%{state | buffer: rest}, line) do
          {:cont, next_state, next_events} ->
            consume_lines(next_state, Enum.reverse(next_events, events))

          {:done, next_state, next_events} ->
            {:done, next_state, Enum.reverse(next_events, events)}

          {:error, reason, next_state, next_events} ->
            {:error, reason, next_state, Enum.reverse(next_events, events)}
        end
    end
  end

  defp consume_line(state, "") do
    data = state.data_lines |> Enum.reverse() |> Enum.join("\n")
    dispatch_event(%{state | data_lines: [], event_bytes: 0}, data)
  end

  defp consume_line(state, <<":", _rest::binary>>), do: {:cont, state, []}
  defp consume_line(state, "data:"), do: add_data(state, "")
  defp consume_line(state, "data: " <> data), do: add_data(state, data)
  defp consume_line(state, "data:" <> data), do: add_data(state, data)
  defp consume_line(state, _other_field), do: {:cont, state, []}

  defp add_data(state, data) do
    event_bytes = state.event_bytes + byte_size(data) + 1

    if event_bytes > @max_event_bytes do
      {:error, :unavailable, %{state | data_lines: [], event_bytes: 0}, []}
    else
      {:cont, %{state | data_lines: [data | state.data_lines], event_bytes: event_bytes}, []}
    end
  end

  defp dispatch_event(state, ""), do: {:cont, state, []}

  defp dispatch_event(state, "[DONE]") do
    {:done, %{state | done?: true}, []}
  end

  defp dispatch_event(state, data) do
    case Jason.decode(data) do
      {:ok, %{"error" => error}} ->
        {:error, classify_provider_error(error), state, []}

      {:ok, payload} when is_map(payload) ->
        {state, events} = normalize_payload(state, payload)
        {:cont, state, events}

      _ ->
        {:error, :unavailable, state, []}
    end
  end

  defp normalize_payload(state, payload) do
    choices =
      case Map.get(payload, "choices", []) do
        choices when is_list(choices) -> choices
        _invalid -> []
      end

    {state, choice_events} =
      Enum.reduce(choices, {state, []}, fn
        choice, {current_state, events} when is_map(choice) ->
          content = delta_content(choice)
          finish_reason = normalize_finish_reason(Map.get(choice, "finish_reason"))

          current_state =
            if finish_reason,
              do: %{current_state | finish_reason: finish_reason},
              else: current_state

          if is_binary(content) and content != "" do
            {current_state, [{:delta, content} | events]}
          else
            {current_state, events}
          end

        _invalid_choice, accumulator ->
          accumulator
      end)

    events =
      case normalize_usage(Map.get(payload, "usage")) do
        nil -> choice_events
        usage -> [{:usage, usage} | choice_events]
      end

    {state, Enum.reverse(events)}
  end

  defp delta_content(%{"delta" => %{"content" => content}}), do: content
  defp delta_content(_choice), do: nil

  defp normalize_finish_reason("length"), do: :length
  defp normalize_finish_reason(reason) when is_binary(reason) and reason != "", do: :stop
  defp normalize_finish_reason(_), do: nil

  defp normalize_usage(%{} = usage) do
    %{}
    |> put_token(:input_tokens, Map.get(usage, "prompt_tokens"))
    |> put_token(:output_tokens, Map.get(usage, "completion_tokens"))
    |> case do
      empty when map_size(empty) == 0 -> nil
      normalized -> normalized
    end
  end

  defp normalize_usage(_), do: nil

  defp put_token(map, key, value) when is_integer(value) and value >= 0,
    do: Map.put(map, key, value)

  defp put_token(map, _key, _value), do: map

  defp classify_provider_error(%{"code" => code}) when code in [429, "429"], do: :rate_limited
  defp classify_provider_error(_safe_ignored_error), do: :unavailable

  defp trim_carriage_return(<<>>), do: <<>>

  defp trim_carriage_return(line) do
    case :binary.last(line) do
      ?\r -> binary_part(line, 0, byte_size(line) - 1)
      _ -> line
    end
  end
end
