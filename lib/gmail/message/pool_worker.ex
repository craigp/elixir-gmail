defmodule Gmail.Message.PoolWorker do

  @moduledoc """
  A message pool worker.
  """

  use GenServer
  alias Gmail.{Message, User}

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({:get, user_id, message_id, params, state}, _from, worker_state) do
    result =
      user_id
      |> Message.get(message_id, params)
      |> User.http_execute(state)
      |> Message.handle_message_response
    {:reply, result, worker_state}
  end

  @doc """
  Gets a message.
  """
  @spec get(pid, String.t, String.t, map, map) :: {atom, map}
  def get(pid, user_id, message_id, params, state) do
    GenServer.call(pid, {:get, user_id, message_id, params, state}, :infinity)
  end

end

