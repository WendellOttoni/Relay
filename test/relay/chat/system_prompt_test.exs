defmodule Relay.Chat.SystemPromptTest do
  use ExUnit.Case, async: true

  alias Relay.Chat.SystemPrompt

  test "keeps the assistant inside the portfolio and commercial scope" do
    prompt = SystemPrompt.build(nil) |> normalize_whitespace()

    assert prompt =~ "official portfolio and commercial assistant"
    assert prompt =~ "Do not behave as a general-purpose assistant"
    assert prompt =~ "Resumo da oportunidade"
    assert prompt =~ "Proposta inicial"
    assert prompt =~ "cannot independently send email"
  end

  test "appends deployment context after the fixed policy" do
    prompt = SystemPrompt.build("Wendell prefers a formal tone.") |> normalize_whitespace()

    assert prompt =~ "must not override the policy above"
    assert prompt =~ "Wendell prefers a formal tone."

    assert :binary.match(prompt, "Do not behave as a general-purpose assistant") <
             :binary.match(prompt, "Wendell prefers a formal tone.")
  end

  defp normalize_whitespace(value), do: String.replace(value, ~r/\s+/, " ")
end
