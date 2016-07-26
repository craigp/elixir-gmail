defmodule Gmail.Message.Worker do

  @moduledoc """
  A worker for fetching messages.
  """

  use GenServer
  use Timex
  require Logger

  @ttl 10
  @tick_interval 1000

  alias Gmail.{Message, User}

  @doc false
  def start_link(message_id, %{user_id: user_id} = state) do
    state = Map.put(state, :message_id, message_id)
    GenServer.start_link(__MODULE__, state, name: build_tag(user_id, message_id))
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
  def terminate(reason, %{message_id: message_id}) do
    Logger.debug "Stopping process for message #{message_id} (#{reason})"
  end

  @doc false
  def handle_call({:get, params}, _from, %{message: message, last_params: params} = state) do
    state = update_ttl(state)
    {:reply, {:ok, message}, state}
  end

  @doc false
  def handle_call({:get, params}, _from, %{message_id: message_id, user_id: user_id} = state) do
    result =
      user_id
      |> Message.get(message_id, params)
      |> User.http_execute(state)
      |> Message.handle_message_response
    case result do
      {:ok, message} ->
        Logger.debug "Caching result for message #{message_id}"
        state = Map.merge(state, %{message: message, last_params: params})
      _otherwise ->
        :noop # TODO fix this, it's awful
    end
    state = update_ttl(state)
    {:reply, result, state}
  end

  @doc """
  Gets a message.
  """
  @spec get(String.t, map, map) :: {atom, map} | {atom, String.t}
  def get(message_id, params, state) do
    message_id
    |> ensure_server_started(state)
    |> GenServer.call({:get, params})
  end

  @doc """
  Fetches multiple messages in parallel.
  """
  @spec fetch({pid, reference}, list, map, map) :: :ok
  def fetch(from, message_ids, params, state) do
    messages =
      message_ids
      |> Enum.map(fn id ->
        Task.async(fn ->
          {:ok, message} = get(id, params, state)
          message
        end)
      end)
      |> Enum.map(&Task.await/1)
    GenServer.reply(from, {:ok, messages})
  end

  @spec update_ttl(map) :: map
  defp update_ttl(%{message_id: message_id} = state) do
    Logger.debug("Updating ttl for message process #{message_id}")
    Map.put(state, :ttl, Time.to_seconds(Time.now) + @ttl)
  end

  @spec ensure_server_started(String.t, map) :: pid
  defp ensure_server_started(message_id, %{user_id: user_id} = state) do
    pid = user_id
    |> build_tag(message_id)
    |> Process.whereis
    if pid do
      Logger.debug "Message process found for #{message_id}"
      pid
    else
      Logger.debug "Starting message process for #{message_id}"
      {:ok, pid} = Supervisor.start_child(Gmail.Message.Supervisor, [message_id, state])
      pid
    end
  end

  @spec build_tag(String.t, String.t) :: atom
  defp build_tag(user_id, message_id) do
    String.to_atom("#{user_id}_#{message_id}")
  end
end
