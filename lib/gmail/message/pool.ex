defmodule Gmail.Message.Pool do

  @moduledoc """
  A pool of workers for handling message operations.
  """

  alias Gmail.Message.PoolWorker
  alias Gmail.Utils
  require Logger

  @default_pool_size 20

  @doc false
  def start_link do
    poolboy_config = [
      {:name, {:local, :__gmail_message_pool}},
      {:worker_module, PoolWorker},
      {:size, pool_size},
      {:max_overflow, 0}
    ]

    children = [
      :poolboy.child_spec(:__gmail_message_pool, poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]

    Supervisor.start_link(children, options)
  end

  @doc """
  Gets a message.
  """
  @spec get(String.t, String.t, map, map) :: {atom, map}
  def get(user_id, message_id, params, state) do
    :poolboy.transaction(
      :__gmail_message_pool,
      fn pid ->
        PoolWorker.get(pid, user_id, message_id, params, state)
      end,
      :infinity)
  end

  @spec pool_size() :: integer
  defp pool_size do
    Utils.load_config(:message, :pool_size, @default_pool_size)
  end

end
