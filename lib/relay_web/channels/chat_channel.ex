defmodule RelayWeb.ChatChannel do
  use RelayWeb, :channel

  alias Relay.Chat.{GenerationLimiter, GenerationWorker, Id, RateLimiter, Request}

  @impl true
  def join("chat:" <> session_id, _payload, socket) do
    if socket.assigns[:session_id] == session_id do
      {:ok, assign(socket, :active_generation, nil)}
    else
      {:error, public_error(:invalid_request)}
    end
  end

  def join(_topic, _payload, _socket), do: {:error, public_error(:invalid_request)}

  @impl true
  def handle_in("chat:generate", payload, socket) when is_map(socket.assigns) do
    if session_expired?(socket) do
      {:reply, {:error, public_error(:session_expired)}, socket}
    else
      handle_valid_session_generate(payload, socket)
    end
  end

  def handle_in("chat:cancel", %{"generationId" => generation_id} = payload, socket)
      when map_size(payload) == 1 and is_binary(generation_id) do
    case socket.assigns[:active_generation] do
      %{generation_id: ^generation_id, worker: worker} = active ->
        GenerationWorker.cancel(worker)

        {:reply, {:ok, %{"status" => "cancelling", "generationId" => generation_id}},
         assign(socket, :active_generation, Map.put(active, :cancelling, true))}

      _none_or_different ->
        {:reply, {:ok, %{"status" => "idle"}}, socket}
    end
  end

  def handle_in("chat:cancel", _payload, socket),
    do: {:reply, {:error, public_error(:invalid_request)}, socket}

  def handle_in(_event, _payload, socket),
    do: {:reply, {:error, public_error(:invalid_request)}, socket}

  defp handle_valid_session_generate(
         _payload,
         %{assigns: %{active_generation: active}} = socket
       )
       when not is_nil(active) do
    {:reply, {:error, public_error(:generation_in_progress)}, socket}
  end

  defp handle_valid_session_generate(payload, socket) do
    do_generate(payload, socket)
  end

  defp do_generate(payload, socket) do
    with :ok <- chat_status(),
         {:ok, request} <- Request.validate(payload, limits()),
         true <- RateLimiter.allow?(socket.assigns.session_id),
         {:ok, lease} <- GenerationLimiter.acquire() do
      start_generation(request, lease, socket)
    else
      :chat_disabled ->
        {:reply, {:error, public_error(:chat_disabled)}, socket}

      {:error, :invalid_request} ->
        {:reply, {:error, public_error(:invalid_request)}, socket}

      false ->
        {:reply, {:error, public_error(:rate_limit_exceeded)}, socket}

      {:error, :overloaded} ->
        {:reply, {:error, public_error(:service_overloaded)}, socket}

      {:error, _reason} ->
        {:reply, {:error, public_error(:internal_error)}, socket}
    end
  end

  defp start_generation(request, lease, socket) do
    ids = %{generation_id: Id.generate(), request_id: Id.generate()}

    case start_worker(request, ids) do
      {:ok, worker} ->
        monitor_ref = Process.monitor(worker)

        active =
          Map.merge(ids, %{worker: worker, monitor_ref: monitor_ref, generation_lease: lease})

        reply = %{
          "status" => "accepted",
          "generationId" => ids.generation_id,
          "requestId" => ids.request_id
        }

        {:reply, {:ok, reply}, assign(socket, :active_generation, active)}

      {:error, _reason} ->
        GenerationLimiter.release(lease)
        {:reply, {:error, public_error(:internal_error)}, socket}
    end
  end

  @impl true
  def handle_info(
        {:chat_generation_event, worker, ids, event},
        %{assigns: %{active_generation: %{worker: worker} = active}} = socket
      ) do
    unless active[:cancelling] == true and not terminal?(event) do
      push_event(socket, event, ids)
    end

    if terminal?(event) do
      Process.demonitor(active.monitor_ref, [:flush])
      release_generation_lease(active)
      {:noreply, assign(socket, :active_generation, nil)}
    else
      {:noreply, socket}
    end
  end

  # Events from cancelled or superseded workers are deliberately ignored.
  def handle_info({:chat_generation_event, _worker, _ids, _event}, socket),
    do: {:noreply, socket}

  def handle_info(
        {:DOWN, ref, :process, worker, :normal},
        %{assigns: %{active_generation: %{monitor_ref: ref, worker: worker}}} = socket
      ) do
    # Terminal messages from a process are delivered before its DOWN. A normal
    # DOWN reaching here therefore means the worker produced no terminal event.
    {:noreply, clear_with_internal_error(socket)}
  end

  def handle_info(
        {:DOWN, ref, :process, worker, _reason},
        %{assigns: %{active_generation: %{monitor_ref: ref, worker: worker}}} = socket
      ) do
    {:noreply, clear_with_internal_error(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def terminate(_reason, socket) do
    case socket.assigns[:active_generation] do
      %{worker: worker} -> GenerationWorker.cancel(worker)
      _none -> :ok
    end

    release_generation_lease(socket.assigns[:active_generation])

    :ok
  end

  defp start_worker(request, ids) do
    {provider, provider_opts} = provider_configuration()

    GenerationWorker.start_child(
      task_supervisor(),
      self(),
      provider,
      request,
      ids,
      provider_opts,
      timeout_ms: Application.get_env(:relay, :chat_timeout_ms, 90_000)
    )
  end

  defp provider_configuration do
    case Application.get_env(:relay, :chat_provider, Relay.Chat.FakeProvider) do
      {provider, opts} when is_atom(provider) and is_list(opts) -> {provider, opts}
      provider when is_atom(provider) -> {provider, []}
    end
  end

  defp chat_status do
    if Application.get_env(:relay, :chat_enabled, false), do: :ok, else: :chat_disabled
  end

  defp task_supervisor,
    do: Application.get_env(:relay, :chat_task_supervisor, Relay.ChatTaskSupervisor)

  defp limits do
    Application.get_env(:relay, :chat_limits, %{})
    |> Map.new()
  end

  defp push_event(socket, :started, ids),
    do: push(socket, "chat:started", base_payload(ids))

  defp push_event(socket, {:delta, sequence, text}, ids) do
    push(
      socket,
      "chat:delta",
      Map.merge(base_payload(ids), %{"sequence" => sequence, "text" => text})
    )
  end

  defp push_event(socket, {:usage, usage}, ids) do
    payload =
      base_payload(ids)
      |> maybe_put("inputTokens", usage[:input_tokens])
      |> maybe_put("outputTokens", usage[:output_tokens])

    push(socket, "chat:usage", payload)
  end

  defp push_event(socket, {:completed, reason}, ids),
    do:
      push(
        socket,
        "chat:completed",
        Map.put(base_payload(ids), "finishReason", Atom.to_string(reason))
      )

  defp push_event(socket, {:error, code}, ids),
    do: push(socket, "chat:error", Map.put(base_payload(ids), "error", error_body(code)))

  defp clear_with_internal_error(socket) do
    active = socket.assigns.active_generation
    push_event(socket, {:error, :internal_error}, active)
    release_generation_lease(active)
    assign(socket, :active_generation, nil)
  end

  defp terminal?({:completed, _reason}), do: true
  defp terminal?({:error, _code}), do: true
  defp terminal?(_event), do: false

  defp base_payload(ids),
    do: %{"generationId" => ids.generation_id, "requestId" => ids.request_id}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp public_error(code), do: %{"error" => error_body(code)}

  defp error_body(:invalid_request),
    do: error("invalid_request", "A solicitação é inválida.", false)

  defp error_body(:generation_in_progress),
    do: error("generation_in_progress", "Já existe uma geração em andamento.", false)

  defp error_body(:rate_limit_exceeded),
    do: error("rate_limit_exceeded", "O limite de uso foi atingido.", true)

  defp error_body(:provider_unavailable),
    do: error("provider_unavailable", "O serviço de IA está temporariamente indisponível.", true)

  defp error_body(:provider_timeout),
    do: error("provider_timeout", "A geração excedeu o tempo limite.", true)

  defp error_body(:chat_disabled),
    do: error("chat_disabled", "O chat está temporariamente indisponível.", true)

  defp error_body(:session_expired),
    do: error("session_expired", "A sessão expirou.", false)

  defp error_body(:internal_error),
    do: error("internal_error", "Não foi possível concluir a geração.", true)

  defp error_body(:service_overloaded),
    do:
      error("service_overloaded", "O serviço está com capacidade temporariamente esgotada.", true)

  defp release_generation_lease(%{generation_lease: lease}), do: GenerationLimiter.release(lease)
  defp release_generation_lease(_active), do: :ok

  defp error(code, message, retryable),
    do: %{"code" => code, "message" => message, "retryable" => retryable}

  defp session_expired?(%{assigns: %{session_expires_at: %DateTime{} = expires_at}}),
    do: DateTime.compare(expires_at, DateTime.utc_now()) != :gt

  defp session_expired?(_socket), do: false
end
