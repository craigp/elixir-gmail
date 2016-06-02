defmodule Gmail.Thread do

  @moduledoc """
  A collection of messages representing a conversation.
  """

  alias __MODULE__
  import Gmail.Base
  alias Gmail.{Helper, Message}

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
  @spec get(String.t, String.t, map) :: {atom, String.t, String.t}
  def get(user_id, thread_id, params) do
    available_options = [:format, :metadata_headers]
    path = querify_params("users/#{user_id}/threads/#{thread_id}", available_options, params)
    {:get, base_url, path}
  end

  @doc """
  Searches for threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec search(String.t, String.t, map) :: {atom, String.t, String.t}
  def search(user_id, query, params) when is_binary(query) do
    list(user_id, Map.put(params, :q, query))
  end

  @doc """
  Lists the threads in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/list
  """
  @spec list(String.t, map) :: {atom, String.t, String.t}
  def list(user_id, params) when is_binary(user_id) do
    available_options = [:max_results, :include_spam_trash, :label_ids, :page_token, :q]
    path = querify_params("users/#{user_id}/threads", available_options, params)
    {:get, base_url, path}
  end

  @doc """
  Immediately and permanently deletes the specified thread. This operation cannot be undone. Prefer `trash` instead.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/delete
  """
  @spec delete(String.t, String.t) :: {atom, String.t, String.t}
  def delete(user_id, thread_id) do
    {:delete, base_url, "users/#{user_id}/threads/#{thread_id}"}
  end

  @doc """
  Moves the specified thread to the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/trash
  """
  @spec trash(String.t, String.t) :: {atom, String.t, String.t}
  def trash(user_id, thread_id) do
    {:post, base_url, "users/#{user_id}/threads/#{thread_id}/trash"}
  end

  @doc """
  Removes the specified thread from the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/untrash
  """
  @spec untrash(String.t, String.t) :: {atom, String.t, String.t}
  def untrash(user_id, thread_id) do
    {:post, base_url, "users/#{user_id}/threads/#{thread_id}/untrash"}
  end

  @doc """
  Handles a thread resource response from the Gmail API.
  """
  def handle_thread_response(response) do
    case response do
      {:ok, %{"error" => %{"code" => 404}} } ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
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
  Handles a thread list response from the Gmail API.
  """
  def handle_thread_list_response(response) do
    case response do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Helper.atomise_keys(thread))
          end)
        {:ok, threads, next_page_token}
      {:ok, %{"threads" => raw_threads}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Helper.atomise_keys(thread))
          end)
        {:ok, threads}
    end
  end

  @doc """
  Handles a thread delete response from the Gmail API.
  """
  def handle_thread_delete_response(response) do
    case response do
      {:ok, %{"error" => %{"code" => 404}} } ->
        :not_found
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}} } ->
        [%{"thread" => error_thread}|_rest] = errors
        {:error, error_thread}
      :ok ->
        :ok
    end
  end

end
