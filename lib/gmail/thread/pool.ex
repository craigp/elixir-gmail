defmodule Gmail.Thread.Pool do

  @moduledoc """
  A pool of workers for handling thread operations.
  """

  alias Gmail.Thread.PoolWorker

  @default_pool_size 20

  @doc false
  def start_link do
    poolboy_config = [
      {:name, {:local, :thread_pool}},
      {:worker_module, PoolWorker},
      {:size, pool_size},
      {:max_overflow, 0}
    ]

    children = [
      :poolboy.child_spec(:thread_pool, poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]

    Supervisor.start_link(children, options)
  end

  @doc """
  Gets a thread.
  """
  @spec get(String.t, String.t, map, map) :: {atom, map}
  def get(user_id, thread_id, params, state) do
    :poolboy.transaction(
      :thread_pool,
      fn pid ->
        PoolWorker.get(pid, user_id, thread_id, params, state)
      end,
      :infinity)
  end

  def pool_size do
    case Application.get_env(:gmail, :thread) do
      [pool: size] when is_integer(size) ->
        size
      _ ->
        @default_pool_size
    end
  end

end
