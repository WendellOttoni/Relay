defmodule RelayWeb.ChatChannelTest do
  use ExUnit.Case, async: false
  import Phoenix.ChannelTest

  @endpoint RelayWeb.Endpoint

  setup do
    supervisor = start_supervised!(Task.Supervisor)
    old_provider = Application.get_env(:relay, :chat_provider)
    old_supervisor = Application.get_env(:relay, :chat_task_supervisor)
    old_chat_enabled = Application.get_env(:relay, :chat_enabled)

    Relay.Chat.GenerationLimiter.reset()

    Application.put_env(:relay, :chat_task_supervisor, supervisor)
    Application.put_env(:relay, :chat_enabled, true)

    on_exit(fn ->
      restore_env(:chat_provider, old_provider)
      restore_env(:chat_task_supervisor, old_supervisor)
      restore_env(:chat_enabled, old_chat_enabled)
      Relay.Chat.GenerationLimiter.reset()
    end)

    %{supervisor: supervisor}
  end

  test "only joins the topic belonging to the socket session" do
    socket = socket(RelayWeb.UserSocket, nil, %{session_id: "own-session"})

    assert {:ok, _, _socket} =
             subscribe_and_join(socket, RelayWeb.ChatChannel, "chat:own-session")

    other_socket = socket(RelayWeb.UserSocket, nil, %{session_id: "own-session"})

    assert {:error, %{"error" => %{"code" => "invalid_request"}}} =
             subscribe_and_join(other_socket, RelayWeb.ChatChannel, "chat:other-session")
  end

  test "publishes the successful protocol in order" do
    Application.put_env(
      :relay,
      :chat_provider,
      {Relay.Chat.FakeProvider,
       events: [{:delta, "Olá"}, {:delta, "!"}, {:usage, %{input_tokens: 1, output_tokens: 2}}]}
    )

    {:ok, _, socket} = join_session("session")

    ref = push(socket, "chat:generate", valid_payload())

    assert_reply ref, :ok, %{
      "status" => "accepted",
      "generationId" => generation_id,
      "requestId" => request_id
    }

    assert_push "chat:started", %{
      "generationId" => ^generation_id,
      "requestId" => ^request_id
    }

    assert_push "chat:delta", %{"sequence" => 1, "text" => "Olá"}
    assert_push "chat:delta", %{"sequence" => 2, "text" => "!"}
    assert_push "chat:usage", %{"inputTokens" => 1, "outputTokens" => 2}
    assert_push "chat:completed", %{"finishReason" => "stop"}
  end

  test "rejects invalid and concurrent generations, then cancels idempotently" do
    Application.put_env(
      :relay,
      :chat_provider,
      {Relay.Chat.FakeProvider, events: [], wait: true}
    )

    {:ok, _, socket} = join_session("session")

    invalid_ref = push(socket, "chat:generate", %{"messages" => []})
    assert_reply invalid_ref, :error, %{"error" => %{"code" => "invalid_request"}}

    first_ref = push(socket, "chat:generate", valid_payload())
    assert_reply first_ref, :ok, %{"generationId" => generation_id}
    assert_push "chat:started", %{"generationId" => ^generation_id}

    second_ref = push(socket, "chat:generate", valid_payload())

    assert_reply second_ref, :error, %{
      "error" => %{"code" => "generation_in_progress"}
    }

    cancel_ref = push(socket, "chat:cancel", %{"generationId" => generation_id})
    assert_reply cancel_ref, :ok, %{"status" => "cancelling"}
    assert_push "chat:completed", %{"finishReason" => "cancelled"}

    cancel_again_ref = push(socket, "chat:cancel", %{"generationId" => generation_id})
    assert_reply cancel_again_ref, :ok, %{"status" => "idle"}
    refute_push "chat:delta", _payload, 20
  end

  test "rejects generations safely while chat is disabled" do
    Application.put_env(:relay, :chat_enabled, false)
    {:ok, _, socket} = join_session("session")

    ref = push(socket, "chat:generate", valid_payload())

    assert_reply ref, :error, %{
      "error" => %{"code" => "chat_disabled", "retryable" => true}
    }
  end

  test "fails closed when all generation capacity is occupied" do
    leases = acquire_all_generation_leases()
    {:ok, _, socket} = join_session("session")

    ref = push(socket, "chat:generate", valid_payload())

    assert_reply ref, :error, %{
      "error" => %{"code" => "service_overloaded", "retryable" => true}
    }

    Enum.each(leases, &Relay.Chat.GenerationLimiter.release/1)
  end

  defp join_session(session_id) do
    RelayWeb.UserSocket
    |> socket(nil, %{session_id: session_id})
    |> subscribe_and_join(RelayWeb.ChatChannel, "chat:#{session_id}")
  end

  defp valid_payload,
    do: %{"messages" => [%{"role" => "user", "content" => "Olá"}]}

  defp restore_env(key, nil), do: Application.delete_env(:relay, key)
  defp restore_env(key, value), do: Application.put_env(:relay, key, value)

  defp acquire_all_generation_leases(leases \\ []) do
    case Relay.Chat.GenerationLimiter.acquire() do
      {:ok, lease} -> acquire_all_generation_leases([lease | leases])
      {:error, :overloaded} -> leases
    end
  end
end
