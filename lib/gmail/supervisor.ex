defmodule Gmail.Supervisor do

  @moduledoc """
  Supervises all the things.
  """

  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    children = [
      worker(Gmail.UserManager, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

end
