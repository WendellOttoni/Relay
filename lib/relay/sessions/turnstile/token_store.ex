defmodule Relay.Sessions.Turnstile.TokenStore do
  @moduledoc """
  Local, expiring replay guard for successfully verified Turnstile tokens.

  Cloudflare also treats Siteverify tokens as single-use. Keeping this guard
  makes the application invariant explicit and atomically protects concurrent
  requests received by this node. Only a SHA-256 digest is retained.
  """

  use GenServer

  @default_ttl_seconds 300

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec consume(String.t(), GenServer.server()) ::
          :ok | {:error, :challenge_replayed | :store_unavailable}
  def consume(token, server \\ __MODULE__) when is_binary(token) do
    GenServer.call(server, {:consume, digest(token)})
  catch
    :exit, _reason -> {:error, :store_unavailable}
  end

  @doc false
  def reset(server \\ __MODULE__) do
    GenServer.call(server, :reset)
  catch
    :exit, _reason -> {:error, :store_unavailable}
  end

  @impl true
  def init(opts) do
    ttl_seconds =
      Keyword.get(
        opts,
        :ttl_seconds,
        Application.get_env(:relay, :turnstile_token_ttl_seconds, @default_ttl_seconds)
      )

    {:ok, %{tokens: %{}, ttl_ms: positive(ttl_seconds, @default_ttl_seconds) * 1_000}}
  end

  @impl true
  def handle_call({:consume, token_digest}, _from, state) do
    now = System.monotonic_time(:millisecond)
    tokens = Map.filter(state.tokens, fn {_digest, expires_at} -> expires_at > now end)

    if Map.has_key?(tokens, token_digest) do
      {:reply, {:error, :challenge_replayed}, %{state | tokens: tokens}}
    else
      {:reply, :ok, %{state | tokens: Map.put(tokens, token_digest, now + state.ttl_ms)}}
    end
  end

  def handle_call(:reset, _from, state), do: {:reply, :ok, %{state | tokens: %{}}}

  defp digest(token), do: :crypto.hash(:sha256, token)
  defp positive(value, _default) when is_integer(value) and value > 0, do: value
  defp positive(_value, default), do: default
end
