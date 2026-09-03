defmodule RelayWeb.ErrorJSON do
  @moduledoc false

  def render(template, _assigns) do
    status = status_from_template(template)

    %{
      error: %{
        code: code(status),
        message: message(status),
        requestId: Process.get(:relay_request_id)
      }
    }
  end

  defp status_from_template(<<status::binary-size(3), ".json">>) do
    case Integer.parse(status) do
      {value, ""} -> value
      _ -> 500
    end
  end

  defp status_from_template(_), do: 500

  defp code(400), do: "invalid_request"
  defp code(403), do: "forbidden"
  defp code(404), do: "not_found"
  defp code(413), do: "payload_too_large"
  defp code(429), do: "rate_limit_exceeded"
  defp code(503), do: "service_unavailable"
  defp code(_), do: "internal_error"

  defp message(400), do: "Requisição inválida."
  defp message(403), do: "Acesso recusado."
  defp message(404), do: "Recurso não encontrado."
  defp message(413), do: "Corpo da requisição excede o limite permitido."
  defp message(429), do: "Limite temporário atingido."
  defp message(503), do: "Serviço temporariamente indisponível."
  defp message(_), do: "Falha interna."
end
