defmodule Relay.Sessions do
  @moduledoc """
  Issues and verifies short-lived credentials for anonymous chat sessions.

  Session tokens are signed by Phoenix using the endpoint secret. They contain
  only a random identifier and an expiry timestamp.
  """

  @token_salt "relay-anonymous-socket-v1"
  @default_ttl_seconds 1_800
  @id_bytes 16

  @type session :: %{
          session_id: String.t(),
          socket_token: String.t(),
          expires_at: DateTime.t()
        }

  @spec create_session(map()) :: {:ok, session()} | {:error, atom()}
  def create_session(attrs) when is_map(attrs) do
    with :ok <- ensure_chat_enabled(),
         {:ok, challenge_token} <- fetch_challenge_token(attrs),
         :ok <- Relay.Sessions.RateLimiter.allow?(network_key(attrs), rate_limiter()),
         :ok <- validator().verify(challenge_token, validation_context(attrs)),
         :ok <- Relay.Sessions.Turnstile.TokenStore.consume(challenge_token, token_store()) do
      issue_session()
    end
  end

  @spec verify_socket_token(String.t()) ::
          {:ok, %{session_id: binary(), expires_at: DateTime.t()}} | {:error, atom()}
  def verify_socket_token(token) when is_binary(token) do
    case Phoenix.Token.verify(RelayWeb.Endpoint, @token_salt, token, max_age: ttl_seconds()) do
      {:ok, payload} -> verify_socket_payload(payload)
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_socket_token(_token), do: {:error, :invalid}

  defp issue_session do
    session_id = @id_bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(ttl_seconds(), :second)
      |> DateTime.truncate(:second)

    payload = %{session_id: session_id, expires_at: DateTime.to_unix(expires_at)}
    socket_token = Phoenix.Token.sign(RelayWeb.Endpoint, @token_salt, payload)

    {:ok, %{session_id: session_id, socket_token: socket_token, expires_at: expires_at}}
  end

  defp fetch_challenge_token(attrs) do
    case Map.get(attrs, :turnstile_token) || Map.get(attrs, "turnstileToken") do
      token when is_binary(token) and byte_size(token) > 0 -> {:ok, token}
      _other -> {:error, :missing_challenge}
    end
  end

  defp ensure_chat_enabled do
    if Application.get_env(:relay, :chat_enabled, false),
      do: :ok,
      else: {:error, :chat_disabled}
  end

  defp validation_context(attrs) do
    %{
      remote_ip: Map.get(attrs, :remote_ip),
      expected_hostname: Application.get_env(:relay, :turnstile_expected_hostname),
      expected_action: Application.get_env(:relay, :turnstile_expected_action)
    }
  end

  defp network_key(attrs),
    do: Map.get(attrs, :network_key) || Map.get(attrs, :remote_ip) || :unknown

  defp decode_payload(%{session_id: session_id, expires_at: unix})
       when is_binary(session_id) and is_integer(unix) and byte_size(session_id) > 0 do
    case DateTime.from_unix(unix) do
      {:ok, expires_at} -> {:ok, session_id, expires_at}
      _error -> {:error, :invalid}
    end
  end

  defp decode_payload(_payload), do: {:error, :invalid}

  defp verify_socket_payload(payload) do
    with {:ok, session_id, expires_at} <- decode_payload(payload),
         :ok <- ensure_not_expired(expires_at) do
      {:ok, %{session_id: session_id, expires_at: expires_at}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_not_expired(expires_at) do
    if DateTime.compare(expires_at, DateTime.utc_now()) == :gt,
      do: :ok,
      else: {:error, :expired}
  end

  defp validator do
    Application.get_env(:relay, :turnstile_validator, Relay.Sessions.Turnstile.Disabled)
  end

  defp rate_limiter do
    Application.get_env(:relay, :session_rate_limiter, Relay.Sessions.RateLimiter)
  end

  defp token_store do
    Application.get_env(:relay, :turnstile_token_store, Relay.Sessions.Turnstile.TokenStore)
  end

  defp ttl_seconds do
    case Application.get_env(:relay, :session_ttl_seconds, @default_ttl_seconds) do
      ttl when is_integer(ttl) and ttl > 0 -> ttl
      _invalid -> @default_ttl_seconds
    end
  end
end
