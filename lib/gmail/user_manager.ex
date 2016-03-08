defmodule Gmail.UserManager do

  @moduledoc """
  Supervises user processes.
  """

  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    [worker(Gmail.User, [], restart: :transient)]
    |> supervise(strategy: :simple_one_for_one)
  end

end
