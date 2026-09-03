defmodule Relay.Config do
  @moduledoc false

  @spec ready?() :: boolean()
  def ready?, do: errors() == []

  @spec errors() :: [String.t()]
  def errors, do: Application.get_env(:relay, :runtime_config_errors, [])

  def require_value(errors, name, value) when value in [nil, ""],
    do: errors ++ ["#{name} is required"]

  def require_value(errors, _name, _value), do: errors

  def require_secret(errors, name, value, minimum_bytes) do
    if is_binary(value) and byte_size(value) >= minimum_bytes do
      errors
    else
      errors ++ ["#{name} is missing or too short"]
    end
  end

  @spec parse_origins(String.t() | nil, atom()) :: {[String.t()], [String.t()]}
  def parse_origins(nil, _environment), do: {[], ["ALLOWED_ORIGINS is required"]}

  def parse_origins(value, environment) do
    origins =
      value
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    errors =
      cond do
        origins == [] -> ["ALLOWED_ORIGINS must contain at least one origin"]
        "*" in origins -> ["ALLOWED_ORIGINS cannot contain a wildcard"]
        "null" in origins -> ["ALLOWED_ORIGINS cannot contain a null origin"]
        true -> Enum.flat_map(origins, &validate_origin(&1, environment))
      end

    {origins, errors}
  end

  @spec websocket_origins([String.t()]) :: [String.t()]
  def websocket_origins(origins) do
    Enum.map(origins, fn origin ->
      uri = URI.parse(origin)
      port = if uri.port in [80, 443, nil], do: "", else: ":#{uri.port}"
      "//#{uri.host}#{port}"
    end)
  end

  defp validate_origin(origin, environment) do
    uri = URI.parse(origin)
    production? = environment == :prod

    cond do
      uri.scheme not in ["http", "https"] or is_nil(uri.host) ->
        ["ALLOWED_ORIGINS contains an invalid origin"]

      uri.path not in [nil, ""] or not is_nil(uri.query) or not is_nil(uri.fragment) ->
        ["ALLOWED_ORIGINS entries must not contain paths, queries, or fragments"]

      production? and uri.scheme != "https" ->
        ["ALLOWED_ORIGINS must use HTTPS in production"]

      production? and uri.host in ["localhost", "127.0.0.1", "::1"] ->
        ["ALLOWED_ORIGINS cannot contain localhost in production"]

      true ->
        []
    end
  end
end
