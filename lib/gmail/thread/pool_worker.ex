defmodule Gmail.Thread.PoolWorker do

  @moduledoc """
  A thread pool worker.
  """

  use GenServer
  alias Gmail.{Thread, User}

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    {:ok, state}
  end

  @doc false
  def handle_call({:get, user_id, thread_id, params, state}, _from, worker_state) do
    result =
      user_id
      |> Thread.get(thread_id, params)
      |> User.http_execute(state)
      |> Thread.handle_thread_response
    {:reply, result, worker_state}
  end

  @doc """
  Gets a thread.
  """
  @spec get(pid, String.t, String.t, map, map) :: {atom, map}
  def get(pid, user_id, thread_id, params, state) do
    GenServer.call(pid, {:get, user_id, thread_id, params, state}, :infinity)
  end

end
