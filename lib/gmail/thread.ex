defmodule Gmail.Thread do

  import Gmail.Base

  @moduledoc """
  A collection of messages representing a conversation.
  """

  @doc """
  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads#resource
  """
  defstruct id: "",
    snippet: "",
    history_id: "",
    messages: []

  @type t :: %__MODULE__{}

  @doc """
  Gets the specified thread.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/get
  """
  @spec get(String.t) :: {:ok, Gmail.Thread.t}
  def get(id), do: get("me", id)

  @doc """
  Gets the specified thread.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/get
  """
  @spec get(String.t, String.t) :: {:ok, Gmail.Thread.t}
  def get(user_id, id) do
    case do_get("users/#{user_id}/threads/#{id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        :not_found
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:error, details} ->
        {:error, details}
      {:ok, %{"id" => id, "historyId" => history_id, "messages" => messages}} ->
        {:ok, %Gmail.Thread{
          id: id,
          history_id: history_id,
          messages: Enum.map(messages, &Gmail.Message.convert/1)
        }}
    end
  end

  @doc """
  Searches for threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec search(String.t) :: [Gmail.Thread.t]
  def search(query), do: search("me", query)

  @doc """
  Searches for threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec search(String.t, String.t) :: [Gmail.Thread.t]
  def search(user_id, query) do
    case do_get("users/#{user_id}/threads?q=#{query}") do
      {:ok, %{"threads" => threads}} ->
        {:ok, Enum.map(
          threads,
          fn(%{"historyId" => history_id, "id" => id, "snippet" => snippet}) ->
            %Gmail.Thread{id: id, history_id: history_id, snippet: snippet}
          end)}
      not_ok ->
        IO.puts "FML"
        not_ok
    end
  end

  @doc """
  Lists the threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec list(String.t, Map.t) :: {:ok, [Gmail.Thread.t], String.t}
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
