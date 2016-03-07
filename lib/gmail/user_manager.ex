defmodule Gmail.UserManager do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    [worker(Gmail.User, [], restart: :transient)]
    |> supervise(strategy: :simple_one_for_one)
  end

end
