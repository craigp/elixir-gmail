defmodule Gmail.Thread do

  import Gmail.Base

  defstruct id: "",
    snippet: "",
    history_id: "",
    messages: []

  @type t :: %__MODULE__{}

  @doc """
  Gets a thread with the specified id
  """
  @spec get(String.t) :: Gmail.Thread.t
  def get(id), do: get("me", id)

  @doc """
  Gets a thread for the specified user with the specified id
  """
  @spec get(String.t, String.t) :: Gmail.Thread.t
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
  @spec search(String.t) :: [Gmail.Thread.t]
  def search(query), do: search("me", query)

  @doc """
  Searches for threads for the specified user
  """
  @spec search(String.t, String.t) :: [Gmail.Thread.t]
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
  @spec list(String.t, Keyword.t) :: [Gmail.Thread.t]
  def list(user_id \\ "me", params \\ %{}) do
    case Enum.empty?(params) do
      true ->
        get_list "users/#{user_id}/threads"
      false ->
        query = %{}
        if Map.has_key?(params, :page_token) do
          query = Map.put(query, "pageToken", params[:page_token])
        end
        if Enum.empty?(query) do
          list(user_id)
        else
          get_list "users/#{user_id}/threads?#{URI.encode_query(query)}"
        end
    end
  end

  @spec get_list(String.t) :: {:ok, [Gmail.Thread.t], String.t}
  defp get_list(url) do
    case do_get(url) do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        threads = Enum.map(raw_threads,
          fn(%{"id" => id, "historyId" => history_id, "snippet" => snippet}) ->
            %Gmail.Thread{id: id, history_id: history_id, snippet: snippet}
          end)
        {:ok, threads, next_page_token}
      not_ok ->
        {:error, not_ok}
    end
  end

end
