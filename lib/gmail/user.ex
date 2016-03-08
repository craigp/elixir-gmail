defmodule Gmail.User do

  @moduledoc """
  Represents a user's mailbox, holding it's config and tokens.
  """

  use GenServer
  alias Gmail.{Thread, Message, Helper, HTTP, Label, Draft}

  #  Server API {{{ #

  @doc false
  def start_link({user_id, refresh_token}) do
    GenServer.start_link(__MODULE__, {user_id, refresh_token}, name: String.to_atom(user_id))
  end

  @doc false
  def init({user_id, refresh_token}) do
    {access_token, expires_at} = Gmail.OAuth2.refresh_access_token(refresh_token)
    state = Map.new(user_id: user_id, refresh_token: refresh_token,
      access_token: access_token, expires_at: expires_at)
    {:ok, state}
  end

  #  Threads {{{ #

  @doc false
  def handle_call({:thread, {:list, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Thread.list(params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
          threads =
            raw_threads
            |> Enum.map(fn thread ->
              struct(Thread, Helper.atomise_keys(thread))
            end)
          {:ok, threads, next_page_token}
        {:ok, %{"threads" => raw_threads}} ->
          threads =
            raw_threads
            |> Enum.map(fn thread ->
              struct(Thread, Helper.atomise_keys(thread))
            end)
          {:ok, threads}
      end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:get, thread_id, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Thread.get(thread_id, params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, %{"id" => id, "historyId" => history_id, "messages" => messages}} ->
          {:ok, %Thread{
              id: id,
              history_id: history_id,
              messages: Enum.map(messages, &Message.convert/1)
            }}
      end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:search, :thread, query, params}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Thread.search(query, params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
          threads =
            raw_threads
            |> Enum.map(fn thread ->
              struct(Thread, Helper.atomise_keys(thread))
            end)
          {:ok, threads, next_page_token}
        {:ok, %{"threads" => raw_threads}} ->
          threads =
            raw_threads
            |> Enum.map(fn thread ->
              struct(Thread, Helper.atomise_keys(thread))
            end)
          {:ok, threads}
      end
    {:reply, result, state}
  end

  #  }}} Threads #

  #  Messages {{{ #

  @doc false
  def handle_call({:message, {:list, params}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Message.list(params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"messages" => msgs}} ->
          {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Message{id: id, thread_id: thread_id} end)}
      end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:get, message_id, params}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Message.get(message_id, params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_message} ->
          {:ok, Message.convert(raw_message)}
      end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:message, {:delete, message_id}}, _from, %{user_id: user_id} = state) do
    result  =
      user_id
      |> Message.delete(message_id)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          :not_found
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, _} ->
          :ok
      end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:search, :message, query, params}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Message.search(query, params)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"messages" => msgs}} ->
          {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Message{id: id, thread_id: thread_id} end)}
      end
    {:reply, result, state}
  end

  #  }}} Messages #

  #  Labels {{{ #

  @doc false
  def handle_call({:label, {:list}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.list
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, %{"labels" => raw_labels}} ->
          {:ok, Enum.map(raw_labels, &Label.convert/1)}
      end
    {:reply, result, state}
  end

  def handle_call({:label, {:get, label_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.get(label_id)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_label} ->
          {:ok, Label.convert(raw_label)}
      end
    {:reply, result, state}
  end

  def handle_call({:label, {:create, label_name}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.create(label_name)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_label} ->
          {:ok, Label.convert(raw_label)}
      end
    {:reply, result, state}
  end

  def handle_call({:label, {:delete, label_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.delete(label_id)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          :not_found
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
          [%{"message" => error_message}|_rest] = errors
          {:error, error_message}
        {:ok, _} ->
          :ok
      end
    {:reply, result, state}
  end

  def handle_call({:label, {:update, label}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.update(label)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_label} ->
          {:ok, Label.convert(raw_label)}
      end
    {:reply, result, state}
  end

  def handle_call({:label, {:patch, label}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Label.patch(label)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => details}} ->
          {:error, details}
        {:ok, raw_label} ->
          {:ok, Label.convert(raw_label)}
      end
    {:reply, result, state}
  end

  #  }}} Labels #

  #  Drafts {{{ #

  def handle_call({:draft, {:list}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.list
      |> HTTP.execute(state)
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
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
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
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        nil ->
          :ok
      end
    {:reply, result, state}
  end

  def handle_call({:draft, {:send, draft_id}}, _from, %{user_id: user_id} = state) do
    result =
      user_id
      |> Draft.send(draft_id)
      |> HTTP.execute(state)
      |> case do
        {:ok, %{"error" => %{"code" => 404}} } ->
          {:error, :not_found}
        {:ok, %{"error" => detail}} ->
          {:error, detail}
        {:ok, %{"threadId" => thread_id}} ->
          {:ok, %{thread_id: thread_id}}
      end
    {:reply, result, state}
  end

  #  }}} Drafts #

  #  }}} Server API #

  #  Client API {{{ #

  #  Server control {{{ #

  @doc """
  Starts the process for the specified user.
  """
  def start(user_id, refresh_token) do
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
  def stop(user_id) do
    :ok =
      user_id
      |> String.to_atom
      |> GenServer.stop(:normal)
  end

  #  }}} Server control #

  #  Threads {{{ #

  @doc """
  Lists the threads in the specified user's mailbox.
  """
  def threads(user_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:thread, {:list, params}}, :infinity)
  end

  @doc """
  Gets a thread from the specified user's mailbox.
  """
  def thread(user_id, thread_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:thread, {:get, thread_id, params}}, :infinity)
  end

  #  }}} Threads #

  #  Messages {{{ #

  @doc """
  Lists the messages in the specified user's mailbox.
  """
  def messages(user_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:message, {:list, params}}, :infinity)
  end

  @doc """
  Deletes the specified message from the user's mailbox.
  """
  def message(:delete, user_id, message_id) do
    GenServer.call(String.to_atom(user_id), {:message, {:delete, message_id}}, :infinity)
  end

  @doc """
  Gets a message from the specified user's mailbox.
  """
  def message(user_id, message_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:message, {:get, message_id, params}}, :infinity)
  end

  @doc """
  Searches for messages or threads in the specified user's mailbox.
  """
  def search(user_id, thread_or_message, query, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:search, thread_or_message, query, params}, :infinity)
  end

  #  }}} Messages #

  #  Labels {{{ #

  @doc """
  Lists all labels in the specified user's mailbox.
  """
  def labels(user_id) do
    GenServer.call(String.to_atom(user_id), {:label, {:list}}, :infinity)
  end

  @doc """
  Gets a label from the specified user's mailbox.
  """
  def label(user_id, label_id) do
    GenServer.call(String.to_atom(user_id), {:label, {:get, label_id}}, :infinity)
  end

  def label(:create, user_id, label_name) do
    GenServer.call(String.to_atom(user_id), {:label, {:create, label_name}}, :infinity)
  end

  def label(:delete, user_id, label_id) do
    GenServer.call(String.to_atom(user_id), {:label, {:delete, label_id}}, :infinity)
  end

  def label(:update, user_id, %Label{} = label) do
    GenServer.call(String.to_atom(user_id), {:label, {:update, label}}, :infinity)
  end

  def label(:patch, user_id, %Label{} = label) do
    GenServer.call(String.to_atom(user_id), {:label, {:patch, label}}, :infinity)
  end

  #  }}} Labels #

  #  Drafts {{{ #

  def drafts(user_id) do
    GenServer.call(String.to_atom(user_id), {:draft, {:list}}, :infinity)
  end

  def draft(user_id, draft_id) do
    GenServer.call(String.to_atom(user_id), {:draft, {:get, draft_id}}, :infinity)
  end

  def draft(:delete, user_id, draft_id) do
    GenServer.call(String.to_atom(user_id), {:draft, {:delete, draft_id}}, :infinity)
  end

  def draft(:send, user_id, draft_id) do
    GenServer.call(String.to_atom(user_id), {:draft, {:send, draft_id}}, :infinity)
  end

  #  }}} Drafts #

  #  }}} Client API #

end
