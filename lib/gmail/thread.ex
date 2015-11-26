defmodule Gmail.Thread do

  import Gmail.Base

  defstruct id: "",
    snippet: "",
    history_id: "",
    messages: []

  @doc """
  Gets a thread
  """
  def get(id), do: get("me", id)

  @doc """
  Gets a thread
  """
  def get(user_id, id) do
    case do_get("users/#{user_id}/threads/#{id}") do
      {:ok, %{"id" => id, "historyId" => history_id, "messages" => messages}} ->
        %Gmail.Thread{
          id: id,
          history_id: history_id,
          messages: Enum.map(messages, &Gmail.Message.convert/1)
        }
    end
  end

  @doc """
  Searches for threads
  """
  def search(query), do: search("me", query)

  @doc """
  Searches for threads
  """
  def search(user_id, query) do
    do_get("users/#{user_id}/threads?q=#{query}")
      # TODO need to parse results
      # {:ok, %{"threads" => msgs}} ->
      #   {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
      # not_ok -> not_ok
    # end
  end

  @doc """
  Gets a list of threads
  """
  def list(user_id \\ "me", params \\ %{}) do
    url = case Enum.empty?(params) do
      true -> "users/#{user_id}/threads"
      false ->
        query = %{}
        if Map.has_key?(params, :page_token) do
          query = Map.put(query, "pageToken", params[:page_token])
        end
        if Enum.empty?(query) do
          list(user_id)
        else
          "users/#{user_id}/threads?#{URI.encode_query(query)}"
        end
    end
    case do_get(url) do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        IO.puts "first"
        threads = Enum.map(raw_threads,
          fn(%{"id" => id, "historyId" => history_id, "snippet" => snippet}) ->
            %Gmail.Thread{id: id, history_id: history_id, snippet: snippet}
          end)
        {:ok, threads, next_page_token}
      not_ok ->
        IO.puts "second"
        not_ok
    end
  end

end
