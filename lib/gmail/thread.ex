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
  @spec get(String.t) :: {atom, Thread.t} | {atom, String.t} | {atom, atom}
  def get(id), do: get(id, %{})

  @doc """
  Gets the specified thread.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/get
  """
  @spec get(String.t, map) :: {atom, Thread.t} | {atom, String.t} | {atom, atom}
  def get(id, params) when is_map(params), do: get(id, "me", params)

  @doc """
  Gets the specified thread.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/get
  """
  @spec get(String.t, String.t) :: {atom, Thread.t} | {atom, String.t} | {atom, atom}
  def get(id, user_id) when is_binary(user_id), do: get(id, user_id, %{})

  @doc """
  Gets the specified thread.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/get
  """
  @spec get(String.t | String.t, String.t) :: {atom, Thread.t} | {atom, String.t} | {atom, atom}
  def get(id, user_id, params) do
    url = if Enum.empty?(params) do
      "users/#{user_id}/threads/#{id}"
    else
      available_options = [:format, :metadata_headers]
      query =
        Map.keys(params)
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          stringKey = Gmail.Helper.camelize(key)
          val = if is_list(params[key]) do
            Enum.join(params[key], ",")
          else
            params[key]
          end
          Map.put(query, stringKey, val)
        end)
      if Enum.empty?(query) do
        "users/#{user_id}/threads/#{id}"
      else
        "users/#{user_id}/threads/#{id}?#{URI.encode_query(query)}"
      end
    end
    case do_get(url) do
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
  def search(user_id \\ "me", query) when is_binary(query), do: list(user_id, %{q: query})

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
    url = if Enum.empty?(params) do
      "users/#{user_id}/threads"
    else
      available_options = [:max_results, :include_spam_trash, :label_ids, :page_token, :q]
      query =
        Map.keys(params)
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          stringKey = Gmail.Helper.camelize(key)
          Map.put(query, stringKey, params[key])
        end)
      if Enum.empty?(query) do
        "users/#{user_id}/threads"
      else
        "users/#{user_id}/threads?#{URI.encode_query(query)}"
      end
    end
    case do_get(url) do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Gmail.Helper.atomise_keys(thread))
          end)
        {:ok, threads, next_page_token}
      {:ok, %{"threads" => raw_threads}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Gmail.Helper.atomise_keys(thread))
          end)
        {:ok, threads}
    end
  end

end
