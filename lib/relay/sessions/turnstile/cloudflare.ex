defmodule Relay.Sessions.Turnstile.Cloudflare do
  @moduledoc """
  Server-side Cloudflare Turnstile Siteverify validator.

  The validator is deliberately fail-closed: a missing secret, an unexpected
  response, or a failed request never grants a session.
  """

  @behaviour Relay.Sessions.TurnstileValidator

  @siteverify_url "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  @impl true
  def verify(token, context) when is_binary(token) and is_map(context) do
    with {:ok, secret} <- secret(),
         {:ok, response} <- siteverify(secret, token, context),
         :ok <- validate_response(response, context) do
      :ok
    else
      {:error, :request_failed} -> {:error, :validator_unavailable}
      {:error, :bad_response} -> {:error, :validator_unavailable}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(_token, _context), do: {:error, :invalid_challenge}

  defp secret do
    case Application.get_env(:relay, :turnstile_secret_key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, :validator_unavailable}
    end
  end

  defp siteverify(secret, token, context) do
    request = %{
      url: Application.get_env(:relay, :turnstile_siteverify_url, @siteverify_url),
      form: siteverify_form(secret, token, context)
    }

    case request_fun().(request) do
      {:ok, %{status: status, body: body}} when status in 200..299 and is_map(body) ->
        {:ok, body}

      {:ok, _response} ->
        {:error, :bad_response}

      {:error, _reason} ->
        {:error, :request_failed}

      _other ->
        {:error, :bad_response}
    end
  rescue
    _exception -> {:error, :request_failed}
  end

  defp request_fun do
    Application.get_env(:relay, :turnstile_request, fn %{url: url, form: form} ->
      Req.post(url, form: form)
    end)
  end

  defp siteverify_form(secret, token, context) do
    [secret: secret, response: token]
    |> maybe_add_remote_ip(Map.get(context, :remote_ip))
  end

  defp maybe_add_remote_ip(form, nil), do: form

  defp maybe_add_remote_ip(form, remote_ip),
    do: Keyword.put(form, :remoteip, format_ip(remote_ip))

  defp format_ip(remote_ip) when is_tuple(remote_ip), do: remote_ip |> :inet.ntoa() |> to_string()
  defp format_ip(remote_ip) when is_binary(remote_ip), do: remote_ip

  defp validate_response(%{"success" => true} = response, context) do
    with :ok <- matches_expected(response, "hostname", Map.get(context, :expected_hostname)),
         :ok <- matches_expected(response, "action", Map.get(context, :expected_action)) do
      :ok
    end
  end

  defp validate_response(_response, _context), do: {:error, :invalid_challenge}

  # An expected value means the response must include that exact value. This
  # prevents a token issued for another hostname or widget action from working.
  defp matches_expected(_response, _field, nil), do: :ok
  defp matches_expected(_response, _field, ""), do: :ok

  defp matches_expected(response, field, expected) when is_binary(expected) do
    if Map.get(response, field) == expected, do: :ok, else: {:error, :invalid_challenge}
  end

  defp matches_expected(_response, _field, _expected), do: {:error, :invalid_challenge}
end
