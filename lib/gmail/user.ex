defmodule Gmail.User do

  @moduledoc """
  TODO
  """

  use GenServer
  alias Gmail.{Thread, Message, Helper, HTTP, Label}

  #  Server API {{{ #

  @doc false
  def start_link({user_id, refresh_token}) do
    GenServer.start_link(__MODULE__, {user_id, refresh_token}, name: String.to_atom(user_id))
  end

  @doc false
  def init({user_id, refresh_token}) do
    # fetch a new access token for this user when the server starts
    {access_token, expires_at} = Gmail.OAuth2.refresh_access_token(user_id, refresh_token)
    state = Map.new(user_id: user_id, refresh_token: refresh_token,
      access_token: access_token, expires_at: expires_at)
    {:ok, state}
  end

  @doc false
  def handle_call({:thread, {:list, params}}, _from, %{user_id: user_id} = state) do
    # Basic flow:
    # 1. fetch a token for the user (either new or exsiting)
    # 2. tokens plus the user ID are packaged as the config
    # 3. call the appropriate api wrapper, passing the config
    # 4. execute an HTTP request
    # 5. parse the results
    # 6. potentially, cache the results
    # 7. return the results
    {_method, _url, _path} = command = Thread.list(user_id, params)
    response = HTTP.execute(command, state)
    result = case response do
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

  def handle_call({:thread, {:get, thread_id, params}}, _from, %{user_id: user_id} = state) do
    command = Thread.get(user_id, thread_id, params)
    response = HTTP.execute(command, state)
    result = case response do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
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

  def handle_call({:message, {:list, params}}, _from, %{user_id: user_id} = state) do
    command = Message.list(user_id)
    response = HTTP.execute(command, state)
    result = case response do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Message{id: id, thread_id: thread_id} end)}
    end
    {:reply, result, state}
  end

  def handle_call({:message, {:get, message_id, params}}, _from, %{user_id: user_id} = state) do
    command = Message.get(user_id, message_id)
    response = HTTP.execute(command, state)
    result = case response do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_message} ->
        {:ok, Message.convert(raw_message)}
    end
    {:reply, result, state}
  end

  def handle_call({:search, :thread, query, params}, _from, %{user_id: user_id} = state) do
    {:reply, nil, state}
  end

  def handle_call({:search, :message, query, params}, _from, %{user_id: user_id} = state) do
    {:reply, nil, state}
  end

  def handle_call({:label, {:list}}, _from, %{user_id: user_id} = state) do
    command = Label.list(user_id)
    response = HTTP.execute(command, state)
    result = case response do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"labels" => raw_labels}} ->
        {:ok, Enum.map(raw_labels, &Label.convert/1)}
    end
    {:reply, result, state}
  end

  def handle_call({:label, {:get, label_id}}, _from, %{user_id: user_id} = state) do
    command = Label.get(user_id, label_id)
    response = HTTP.execute(command, state)
    result = case response do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, Label.convert(raw_label)}
    end
    {:reply, result, state}
  end

  #  }}} Server API #

  #  Client API {{{ #

  @doc """
  Starts a process for dealing with the mail belonging to a specific user.
  """
  def start(user_id, refresh_token) do
    case Supervisor.start_child(Gmail.UserManager, [{user_id, refresh_token}]) do
      {:ok, _pid} ->
        :ok
      {:error, {:already_started, _pid}} ->
        :ok
      {:error, details} ->
        {:error, details}
    end
  end

  @doc """
  Lists the threads in the specified user's mailbox.
  """
  def threads(user_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:thread, {:list, params}})
  end

  @doc """
  Gets a thread from the specified user's mailbox.
  """
  def thread(user_id, thread_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:thread, {:get, thread_id, params}})
  end

  def messages(user_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:message, {:list, params}})
  end

  def message(user_id, message_id, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:message, {:get, message_id, params}})
  end

  def search(user_id, thread_or_message, query, params \\ %{}) do
    GenServer.call(String.to_atom(user_id), {:search, thread_or_message, query, params})
  end

  def labels(user_id) do
    GenServer.call(String.to_atom(user_id), {:label, {:list}})
  end

  def label(user_id, label_id) do
    GenServer.call(String.to_atom(user_id), {:label, {:get, label_id}})
  end

  #  }}} Client API #

end
