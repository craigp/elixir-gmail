defmodule Gmail do

  def search(query) do
    task = Task.async(Gmail.Thread, :search, [query])
    Task.await(task)
  end

  def threads do
    task = Task.async(Gmail.Thread, :list, [])
    Task.await(task)
  end

  def thread(id) do
    task = Task.async(Gmail.Thread, :get, [id])
    Task.await(task)
  end

  def messages do
    task = Task.async(Gmail.Message, :list, [])
    Task.await(task)
  end

  def message(id) do
    task = Task.async(Gmail.Message, :get, [id])
    Task.await(task)
  end

end
