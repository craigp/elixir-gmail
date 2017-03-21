defmodule Gmail.Thread do

  @moduledoc """
  A collection of messages representing a conversation.
  """

  alias __MODULE__
  import Gmail.Base
  alias Gmail.{Utils, Message}

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
    {:get, base_url(), path}
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
    {:get, base_url(), path}
  end

  @doc """
  Immediately and permanently deletes the specified thread. This operation cannot be undone. Prefer `trash` instead.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/delete
  """
  @spec delete(String.t, String.t) :: {atom, String.t, String.t}
  def delete(user_id, thread_id) do
    {:delete, base_url(), "users/#{user_id}/threads/#{thread_id}"}
  end

  @doc """
  Moves the specified thread to the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/trash
  """
  @spec trash(String.t, String.t) :: {atom, String.t, String.t}
  def trash(user_id, thread_id) do
    {:post, base_url(), "users/#{user_id}/threads/#{thread_id}/trash"}
  end

  @doc """
  Removes the specified thread from the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/threads/untrash
  """
  @spec untrash(String.t, String.t) :: {atom, String.t, String.t}
  def untrash(user_id, thread_id) do
    {:post, base_url(), "users/#{user_id}/threads/#{thread_id}/untrash"}
  end

  @doc """
  Handles a thread resource response from the Gmail API.
  """
  @spec handle_thread_response({atom, String.t}) :: {atom, String.t} | {atom, map}
  @spec handle_thread_response({atom, map}) :: {atom, String.t} | {atom, map}
  def handle_thread_response(response) do
    response
    |> handle_error
    |> case do
      {:error, detail} ->
        {:error, detail}
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
  @spec handle_thread_list_response(atom | {atom, map | String.t}) :: {atom, String.t | map} | {atom, map, String.t}
  def handle_thread_list_response(response) do
    response
    |> handle_error
    |> case do
      {:error, detail} ->
        {:error, detail}
      {:ok, %{"threads" => raw_threads, "nextPageToken" => next_page_token}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Utils.atomise_keys(thread))
          end)
        {:ok, threads, next_page_token}
      {:ok, %{"threads" => raw_threads}} ->
        threads =
          raw_threads
          |> Enum.map(fn thread ->
            struct(Thread, Utils.atomise_keys(thread))
          end)
        {:ok, threads}
      {:ok, %{"resultSizeEstimate" => 0}} ->
        {:ok, []}
    end
  end

  @doc """
  Handles a thread delete response from the Gmail API.
  """
  @spec handle_thread_delete_response({atom, map}) :: {atom, String.t | map} | {atom, map, String.t} | atom
  @spec handle_thread_delete_response({atom, String.t}) :: {atom, String.t | map} | {atom, map, String.t} | atom
  def handle_thread_delete_response(response) do
    response
    |> handle_error
    |> case do
      {:error, detail} ->
        {:error, detail}
      {:ok, _} ->
        :ok
    end
  end

end
