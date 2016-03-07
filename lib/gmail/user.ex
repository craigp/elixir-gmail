defmodule Gmail.User do
  use GenServer

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
    {_method, _url, _path} = command = Gmail.Thread.list(state, params)
    response = Gmail.HTTP.execute(command, state)
    result = case response do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Gmail.Thread, Gmail.Helper.atomise_keys(thread))
          end)
        {:ok, threads, next_page_token}
      {:ok, %{"threads" => raw_threads}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Gmail.Thread, Gmail.Helper.atomise_keys(thread))
          end)
        {:ok, threads}
    end
    {:reply, result, state}
  end

  @doc false
  def handle_call({:thread, {:get, thread_id, params}}, _from, %{user_id: user_id} = state) do
    response = Gmail.Thread.get(user_id, thread_id, params)
    {:reply, response, state}
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

  #  }}} Client API #

end
