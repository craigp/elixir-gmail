defmodule Gmail.Thread do

  @moduledoc """
  A collection of messages representing a conversation.
  """

  alias __MODULE__
  alias Gmail.Message
  import Gmail.Base

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
  @spec get(String.t | String.t, String.t) :: {atom, Thread.t} | {atom, String.t} | {atom, atom}
  def get(id, user_id \\ "me", format \\ "full")

  def get(id, user_id, format) do
    case do_get("users/#{user_id}/threads/#{id}?format=#{format}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"id" => id, "historyId" => history_id, "messages" => messages}} ->
        {:ok, %Thread{
          id: id,
          history_id: history_id,
          messages: Enum.map(messages, &Message.convert/1)
        }}
    end
  end

  @doc """
  Searches for threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec search(String.t | String.t, String.t) :: {atom, [Thread.t]}
  def search(query, user_id \\ "me") do
    list(user_id, %{q: query})
  end

  @doc """
  Lists the threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec list(map) :: {atom, [Thread.t], String.t}
  def list(params) when is_map(params), do: list("me", params)

  @doc """
  Lists the threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec list(String.t, map) :: {atom, [Thread.t], String.t}
  def list(user_id \\ "me", params \\ %{}) do
    if Enum.empty?(params) do
      do_list "users/#{user_id}/threads"
    else
      available_options = [:max_results, :include_spam_trash, :label_ids, :page_token, :q]
      query =
        Map.keys(params)
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          IO.puts "using option #{key}"
          stringKey = Gmail.Helper.camelize(key)
          IO.puts "stringKey #{stringKey}"
          Map.put(query, stringKey, params[key])
        end)
      if Enum.empty?(query) do
        list(user_id)
      else
        do_list "users/#{user_id}/threads?#{URI.encode_query(query)}"
      end
    end
  end

  @spec do_list(String.t) :: {atom, [Thread.t], String.t}
  defp do_list(url) do
    case do_get(url) do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        # threads = Enum.map(raw_threads,
        #   fn(%{"id" => id, "historyId" => history_id, "snippet" => snippet}) ->
        #     %Thread{id: id, history_id: history_id, snippet: snippet}
        #   end)
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            Gmail.Helper.atomise_keys(thread)
          end)
        {:ok, threads, next_page_token}
      {:ok, %{"threads" => raw_threads}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            Gmail.Helper.atomise_keys(thread)
          end)
        {:ok, threads}
    end
  end

end
