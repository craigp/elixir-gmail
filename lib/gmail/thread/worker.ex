defmodule Gmail.Thread.Worker do

  @moduledoc """
  A worker process for fetching threads.
  """

  use GenServer
  use Timex
  require Logger

  @ttl 10
  @tick_interval 1000

  alias Gmail.{Thread, User}

  @doc false
  def start_link(thread_id, %{user_id: user_id} = state) do
    state = Map.put(state, :thread_id, thread_id)
    GenServer.start_link(__MODULE__, state, name: build_tag(user_id, thread_id))
  end

  @doc """
  Initialises the process with a supplied TTL rather than the default TTL.
  """
  def init(%{ttl: ttl, user_id: user_id} = state) do
    state = Map.put(state, :ttl, Time.to_seconds(Time.now) + ttl)
    Process.send_after(self, :tick, @tick_interval)
    Logger.debug "Subscribing to parent"
    Gmail.User.subscribe(user_id, self)
    {:ok, state}
  end

  @doc """
  Initialises the process with the default TTL.
  """
  def init(%{user_id: user_id} = state) do
    state = Map.put(state, :ttl, Time.to_seconds(Time.now) + @ttl)
    Process.send_after(self, :tick, @tick_interval)
    Logger.debug "Subscribing to parent"
    Gmail.User.subscribe(user_id, self)
    {:ok, state}
  end

  @doc false
  def handle_info(:tick, %{ttl: ttl} = state) do
    if Time.to_seconds(Time.now) - ttl > @ttl do
      GenServer.cast(self, :stop)
    else
      Process.send_after(self, :tick, @tick_interval)
    end
    {:noreply, state}
  end

  @doc false
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  @doc false
  def terminate(reason, %{thread_id: thread_id}) do
    Logger.debug "Stopping process for thread #{thread_id} (#{reason})"
  end

  @doc false
  def handle_call({:get, params}, _from, %{thread: thread, last_params: params} = state) do
    state = update_ttl(state)
    {:reply, {:ok, thread}, state}
  end

  @doc false
  def handle_call({:get, params}, _from, %{thread_id: thread_id, user_id: user_id} = state) do
    result =
      user_id
      |> Thread.get(thread_id, params)
      |> User.http_execute(state)
      |> Thread.handle_thread_response
    case result do
      {:ok, thread} ->
        Logger.debug "Caching result for thread #{thread_id}"
        state = Map.merge(state, %{thread: thread, last_params: params})
      _otherwise ->
        :noop # TODO fix this, it's awful
    end
    state = update_ttl(state)
    {:reply, result, state}
  end

  @doc """
  Gets a thread.
  """
  @spec get(String.t, map, map) :: {atom, map} | {atom, String.t}
  def get(thread_id, params, state) do
    thread_id
    |> ensure_server_started(state)
    |> GenServer.call({:get, params})
  end

  @doc """
  Fetches multiple threads in parallel.
  """
  @spec fetch({pid, reference}, list, map, map) :: :ok
  def fetch(from, thread_ids, params, state) do
    threads =
      thread_ids
      |> Enum.map(fn id ->
        Task.async(fn ->
          {:ok, thread} = get(id, params, state)
          thread
        end)
      end)
      |> Enum.map(&Task.await/1)
    GenServer.reply(from, {:ok, threads})
  end

  @spec update_ttl(map) :: map
  defp update_ttl(%{thread_id: thread_id} = state) do
    Logger.debug("Updating ttl for thread process #{thread_id}")
    Map.put(state, :ttl, Time.to_seconds(Time.now) + @ttl)
  end

  @spec ensure_server_started(String.t, map) :: pid
  defp ensure_server_started(thread_id, %{user_id: user_id} = state) do
    pid = user_id
    |> build_tag(thread_id)
    |> Process.whereis
    if pid do
      Logger.debug "Thread process found for #{thread_id}"
      pid
    else
      Logger.debug "Starting thread process for #{thread_id}"
      {:ok, pid} = Supervisor.start_child(Gmail.Thread.Supervisor, [thread_id, state])
      pid
    end
  end

  @spec build_tag(String.t, String.t) :: atom
  defp build_tag(user_id, thread_id) do
    String.to_atom("#{user_id}_#{thread_id}")
  end

end
