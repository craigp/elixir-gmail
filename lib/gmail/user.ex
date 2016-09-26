defmodule Gmail.User do
  require Logger

  @moduledoc """
  Represents a user's mailbox, holding it's config and tokens.
  """

  use GenServer
  alias Gmail.{Thread, Message, MessageAttachment, HTTP, Label, Draft, OAuth2, History}

  #  Server API {{{ #

  @doc false
  def start_link({user_id, refresh_token}) do
    GenServer.start_link(__MODULE__, {user_id, refresh_token}, name: String.to_atom(user_id))
  end

  @doc false
  def init({user_id, refresh_token}) do
    {access_token, expires_at} = OAuth2.refresh_access_token(refresh_token)
    state = Map.new(user_id: user_id, refresh_token: refresh_token,
      access_token: access_token, expires_at: expires_at)
    {:ok, state}
  end

  @doc false
  def handle_cast({:update_access_token, access_token, expires_at}, state) do
    {:noreply, %{state | access_token: access_token, expires_at: expires_at}}
  end

  @doc false
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  #  Threads {{{ #

  @doc false
  def handle_call({:thread, {:list, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Thread.list(params)
      |> http_execute(state)
      |> Thread.handle_thread_list_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:get, thread_ids, params}}, _from, %{user_id: user_id} = state) when is_list(thread_ids) do
    threads =
      thread_ids
      |> Enum.map(fn id ->
        Task.async(fn ->
          {:ok, thread} = Gmail.Thread.Pool.get(user_id, id, params, state)
          thread
        end)
      end)
      |> Enum.map(fn task -> Task.await(task, :infinity) end)
    {:reply, {:ok, threads}, state}
  end

  @doc false
  def handle_call({:thread, {:get, thread_id, params}}, _from, %{user_id: user_id} = state) do
    result = Gmail.Thread.Pool.get(user_id, thread_id, params, state)
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:delete, thread_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Thread.delete(thread_id)
      |> http_execute(state)
      |> Thread.handle_thread_delete_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:trash, thread_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Thread.trash(thread_id)
      |> http_execute(state)
      |> Thread.handle_thread_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:untrash, thread_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Thread.untrash(thread_id)
      |> http_execute(state)
      |> Thread.handle_thread_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:search, :thread, query, params}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Thread.search(query, params)
      |> http_execute(state)
      |> Thread.handle_thread_list_response
    {:reply, result, state}
  end

  #  }}} Threads #

  #  Messages {{{ #

  @doc false
  def handle_call({:message, {:list, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Message.list(params)
      |> http_execute(state)
      |> Message.handle_message_list_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:get, message_ids, params}}, _from, %{user_id: user_id} = state) when is_list(message_ids) do
    messages =
      message_ids
      |> Enum.map(fn id ->
        Task.async(fn ->
          {:ok, message} = Gmail.Message.Pool.get(user_id, id, params, state)
          message
        end)
      end)
      |> Enum.map(fn task -> Task.await(task, :infinity) end)
    {:reply, {:ok, messages}, state}
  end

  @doc false
  def handle_call({:message, {:get, message_id, params}}, _from, %{user_id: user_id} = state) do
    result = Gmail.Message.Pool.get(user_id, message_id, params, state)
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:delete, message_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Message.delete(message_id)
      |> http_execute(state)
      |> Message.handle_message_delete_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:trash, message_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Message.trash(message_id)
      |> http_execute(state)
      |> Message.handle_message_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:untrash, message_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Message.untrash(message_id)
      |> http_execute(state)
      |> Message.handle_message_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:search, :message, query, params}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Message.search(query, params)
      |> http_execute(state)
      |> Message.handle_message_list_response
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:modify, message_id, labels_to_add, labels_to_remove}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Message.modify(message_id, labels_to_add, labels_to_remove)
      |> http_execute(state)
      |> Message.handle_message_response
    {:reply, result, state}
  end

  #  }}} Messages #

  #  Attachments {{{ #

  @doc false
  def handle_call({:attachment, {:get, message_id, id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> MessageAttachment.get(message_id, id)
      |> http_execute(state)
      |> MessageAttachment.handle_attachment_response
    {:reply, result, state}
  end

  #  }}} Attachments #

  #  Labels {{{ #

  @doc false
  def handle_call({:label, {:list}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.list
      |> http_execute(state)
      |> Label.handle_label_list_response
    {:reply, result, state}
  end

  def handle_call({:label, {:get, label_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.get(label_id)
      |> http_execute(state)
      |> Label.handle_label_response
    {:reply, result, state}
  end

  def handle_call({:label, {:create, label_name}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.create(label_name)
      |> http_execute(state)
      |> Label.handle_label_response
    {:reply, result, state}
  end

  def handle_call({:label, {:delete, label_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.delete(label_id)
      |> http_execute(state)
      |> Label.handle_label_delete_response
    {:reply, result, state}
  end

  def handle_call({:label, {:update, label}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.update(label)
      |> http_execute(state)
      |> Label.handle_label_response
    {:reply, result, state}
  end

  def handle_call({:label, {:patch, label}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.patch(label)
      |> http_execute(state)
      |> Label.handle_label_response
    {:reply, result, state}
  end

  #  }}} Labels #

  #  Drafts {{{ #

  def handle_call({:draft, {:list}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.list
      |> http_execute(state)
      |> case do
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, %{"resultSizeEstimate" => 0}} ->
          {:ok, []}
        {:ok, %{"drafts" => raw_drafts}} ->
          {:ok, Enum.map(raw_drafts, &Draft.convert/1)}
      end
    {:reply, result, state}
  end

  def handle_call({:draft, {:get, draft_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.get(draft_id)
      |> http_execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}}} ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_message} ->
          {:ok, Draft.convert(raw_message)}
      end
    {:reply, result, state}
  end

  def handle_call({:draft, {:delete, draft_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.delete(draft_id)
      |> http_execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}}} ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        :ok ->
          :ok
      end
    {:reply, result, state}
  end

  def handle_call({:draft, {:send, draft_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.send(draft_id)
      |> http_execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}}} ->
          {:error, :not_found}
        {:ok, %{"error" => detail}} ->
          {:error, detail}
        {:ok, %{"threadId" => thread_id}} ->
          {:ok, %{thread_id: thread_id}}
      end
    {:reply, result, state}
  end

  #  }}} Drafts #

  #  History {{{ #

  @doc false
  def handle_call({:history, {:list, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> History.list(params)
      |> http_execute(state)
      |> History.handle_history_response
    {:reply, result, state}
  end

  #  }}} History #

  #  }}} Server API #

  #  Client API {{{ #

  #  Server control {{{ #

  @doc """
  Starts the process for the specified user.
  """
  @spec start_mail(String.t, String.t) :: {atom, pid} | {atom, map}
  def start_mail(user_id, refresh_token) do
    case Supervisor.start_child(Gmail.UserManager, [{user_id, refresh_token}]) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      {:error, details} ->
        {:error, details}
    end
  end

  @doc """
  Stops the process for the specified user.
  """
  @spec stop_mail(atom | String.t) :: :ok
  def stop_mail(user_id) when is_binary(user_id), do: user_id |> String.to_atom |> stop_mail

  def stop_mail(user_id) when is_atom(user_id) do
    if Process.whereis(user_id) do
      GenServer.cast(user_id, :stop)
    else
      :ok
    end
  end

  #  }}} Server control #

  #  Threads {{{ #

  @spec threads(String.t) :: atom
  @spec threads(String.t, map) :: atom
  @spec threads(String.t, list) :: atom
  @spec threads(String.t, list, map) :: atom
  @spec thread(String.t, String.t) :: atom
  @spec thread(String.t, String.t, map) :: atom
  @spec thread(atom, String.t, String.t) :: atom

  @doc """
  Lists the threads in the specified user's mailbox.
  """
  def threads(user_id), do: threads(user_id, %{})

  def threads(user_id, params) when is_map(params) do
    call(user_id, {:thread, {:list, params}}, :infinity)
  end

  @doc """
  Gets all the requested threads from the specified user's mailbox.
  """
  def threads(user_id, thread_ids) when is_list(thread_ids), do: threads(user_id, thread_ids, %{})

  def threads(user_id, thread_ids, params) when is_list(thread_ids) do
    call(user_id, {:thread, {:get, thread_ids, params}}, :infinity)
  end

  @doc """
  Gets a thread from the specified user's mailbox.
  """
  def thread(user_id, thread_id) when is_binary(user_id), do: thread(user_id, thread_id, %{})

  def thread(user_id, thread_id, params) when is_binary(user_id) do
    call(user_id, {:thread, {:get, thread_id, params}}, :infinity)
  end

  @doc """
  Deletes the specified thread from the user's mailbox.
  """
  def thread(:delete, user_id, thread_id) do
    call(user_id, {:thread, {:delete, thread_id}}, :infinity)
  end

  @doc """
  Trashes the specified thread from the user's mailbox.
  """
  def thread(:trash, user_id, thread_id) do
    call(user_id, {:thread, {:trash, thread_id}}, :infinity)
  end

  @doc """
  Removes the specified thread from the trash in the user's mailbox.
  """
  def thread(:untrash, user_id, thread_id) do
    call(user_id, {:thread, {:untrash, thread_id}}, :infinity)
  end

  #  }}} Threads #

  #  Messages {{{ #

  @spec messages(atom | String.t, map) :: atom
  @spec message(atom | String.t, String.t, map) :: atom
  @spec search(atom | String.t, atom, String.t, map) :: atom

  @doc """
  Lists the messages in the specified user's mailbox.
  """
  def messages(user_id), do: messages(user_id, %{})

  def messages(user_id, params) when is_map(params) do
    call(user_id, {:message, {:list, params}}, :infinity)
  end

  @doc """
  Gets all the requested messages from the specified user's mailbox.
  """
  def messages(user_id, message_ids) when is_list(message_ids), do: messages(user_id, message_ids, %{})

  def messages(user_id, message_ids, params) when is_list(message_ids) do
    call(user_id, {:message, {:get, message_ids, params}}, :infinity)
  end

  @doc """
  Gets a message from the specified user's mailbox.
  """
  def message(user_id, message_id) when is_binary(user_id), do: message(user_id, message_id, %{})

  @doc """
  Gets a message from the specified user's mailbox.
  """
  def message(user_id, message_id, params) when is_binary(user_id) do
    call(user_id, {:message, {:get, message_id, params}}, :infinity)
  end

  @doc """
  Deletes the specified message from the user's mailbox.
  """
  def message(:delete, user_id, message_id) do
    call(user_id, {:message, {:delete, message_id}}, :infinity)
  end

  @doc """
  Trashes the specified message from the user's mailbox.
  """
  def message(:trash, user_id, message_id) do
    call(user_id, {:message, {:trash, message_id}}, :infinity)
  end

  @doc """
  Removes the specified message from the trash in the user's mailbox.
  """
  def message(:untrash, user_id, message_id) do
    call(user_id, {:message, {:untrash, message_id}}, :infinity)
  end

  @doc """
  Searches for messages or threads in the specified user's mailbox.
  """
  def search(user_id, thread_or_message, query, params \\ %{}) do
    call(user_id, {:search, thread_or_message, query, params}, :infinity)
  end

  @doc """
  Modifies the labels on a message in the specified user's mailbox.
  """
  def message(:modify, user_id, message_id, labels_to_add, labels_to_remove) do
    call(user_id, {:message, {:modify, message_id, labels_to_add, labels_to_remove}})
  end

  #  }}} Messages #

  #  Attachments {{{ #

  @spec message(atom | String.t, String.t, map) :: atom

  @doc """
  Gets an attachment from the specified user's mailbox.
  """
  def attachment(user_id, message_id, id) do
    call(user_id, {:attachment, {:get, message_id, id}})
  end

  #  }}} Attachments #

  #  Labels {{{ #

  @spec labels(String.t) :: atom
  @spec label(String.t, String.t) :: atom
  @spec label(atom, String.t, map) :: atom

  @doc """
  Lists all labels in the specified user's mailbox.
  """
  def labels(user_id) do
    call(user_id, {:label, {:list}}, :infinity)
  end

  @doc """
  Gets a label from the specified user's mailbox.
  """
  def label(user_id, label_id) do
    call(user_id, {:label, {:get, label_id}}, :infinity)
  end

  @doc """
  Creates a label in the specified user's mailbox.
  """
  @spec label(atom, String.t, String.t) :: atom
  def label(:create, user_id, label_name) do
    call(user_id, {:label, {:create, label_name}}, :infinity)
  end

  @doc """
  Deletes a label from the specified user's mailbox.
  """
  def label(:delete, user_id, label_id) do
    call(user_id, {:label, {:delete, label_id}}, :infinity)
  end

  @doc """
  Updates a label in the specified user's mailbox.
  """
  def label(:update, user_id, %Label{} = label) do
    call(user_id, {:label, {:update, label}}, :infinity)
  end

  @doc """
  Patches a label in the specified user's mailbox.
  """
  def label(:patch, user_id, %Label{} = label) do
    call(user_id, {:label, {:patch, label}}, :infinity)
  end

  #  }}} Labels #

  #  Drafts {{{ #

  @spec drafts(String.t) :: atom
  @spec draft(String.t, String.t) :: atom
  @spec draft(atom, String.t, String.t) :: atom

  @doc """
  Lists the drafts in the specified user's mailbox.
  """
  def drafts(user_id) do
    call(user_id, {:draft, {:list}}, :infinity)
  end

  @doc """
  Gets a draft from the specified user's mailbox.
  """
  def draft(user_id, draft_id) do
    call(user_id, {:draft, {:get, draft_id}}, :infinity)
  end

  @doc """
  Deletes a draft from the specified user's mailbox.
  """
  def draft(:delete, user_id, draft_id) do
    call(user_id, {:draft, {:delete, draft_id}}, :infinity)
  end

  @doc """
  Sends a draft from the specified user's mailbox.
  """
  def draft(:send, user_id, draft_id) do
    call(user_id, {:draft, {:send, draft_id}}, :infinity)
  end

  #  }}} Drafts #

  #  History {{{ #

  @spec history(String.t, map) :: atom

  @doc """
  Lists the hsitory for the specified user's mailbox.
  """
  def history(user_id, params \\ %{}) do
    call(user_id, {:history, {:list, params}}, :infinity)
  end

  #  }}} History #

  @doc """
  Executes an HTTP action.
  """
  @spec http_execute({atom, String.t, String.t} | {atom, String.t, String.t, map}, map) :: atom | {atom, map | String.t}
  def http_execute(action, %{refresh_token: refresh_token, user_id: user_id} = state) do
    state = if OAuth2.access_token_expired?(state) do
      Logger.debug "Refreshing access token for #{user_id}"
      {access_token, expires_at} = OAuth2.refresh_access_token(refresh_token)
      GenServer.cast(String.to_atom(user_id), {:update_access_token, access_token, expires_at})
      %{state | access_token: access_token}
    else
      state
    end
    HTTP.execute(action, state)
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec call(String.t | atom, tuple, number | atom) :: atom
  defp call(user_id, action, timeout \\ :infinity)

  defp call(user_id, action, timeout) when is_binary(user_id) do
    user_id |> String.to_atom |> call(action, timeout)
  end

  defp call(user_id, action, timeout) when is_atom(user_id) do
    GenServer.call(user_id, action, timeout)
  end

  #  }}} Private functions #

end
