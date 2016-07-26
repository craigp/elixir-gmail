defmodule Gmail.Message.Supervisor do

  @moduledoc """
  Supervises worker processes for fetching messages.
  """

  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link __MODULE__, :ok, name: __MODULE__
  end

  @doc false
  def init(:ok) do
    [
      worker(Gmail.Message.Worker, [], restart: :transient)
    ] |> supervise(strategy: :simple_one_for_one)
  end

end

