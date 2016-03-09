defmodule Gmail.Thread do

  @moduledoc """
  A collection of messages representing a conversation.
  """

  import Gmail.Base
  alias Gmail.{Helper}

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
    path = if Enum.empty?(params) do
      "users/#{user_id}/threads/#{thread_id}"
    else
      available_options = [:format, :metadata_headers]
      query =
        params
        |> Map.keys
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          string_key = Helper.camelize(key)
          val = if is_list(params[key]) do
            Enum.join(params[key], ",")
          else
            params[key]
          end
          Map.put(query, string_key, val)
        end)
      if Enum.empty?(query) do
        "users/#{user_id}/threads/#{thread_id}"
      else
        "users/#{user_id}/threads/#{thread_id}?#{URI.encode_query(query)}"
      end
    end
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
    path = if Enum.empty?(params) do
      "users/#{user_id}/threads"
    else
      available_options = [:max_results, :include_spam_trash, :label_ids, :page_token, :q]
      query =
        params
        |> Map.keys
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          string_key = Helper.camelize(key)
          Map.put(query, string_key, params[key])
        end)
      if Enum.empty?(query) do
        "users/#{user_id}/threads"
      else
        "users/#{user_id}/threads?#{URI.encode_query(query)}"
      end
    end
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

end
