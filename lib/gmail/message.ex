defmodule Gmail.Message do

  @moduledoc """
  An email message.
  """

  alias __MODULE__
  alias Gmail.{Payload, Helper}
  import Gmail.Base

  @doc """
  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages#resource
  """
  defstruct id: "",
    thread_id: "",
    label_ids: [],
    snippet: "",
    history_id: nil,
    payload: %Gmail.Payload{},
    size_estimate: nil,
    raw: ""

  @type t :: %__MODULE__{}

  @doc """
  Gets the specified message.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/get
  """
  @spec get(String.t, String.t, map) :: {atom, String.t, String.t}
  def get(user_id, message_id, params) do
    available_options = [:format, :metadata_headers]
    path = querify_params("users/#{user_id}/messages/#{message_id}", available_options, params)
    {:get, base_url, path}
  end

  @doc """
  Immediately and permanently deletes the specified message. This operation cannot be undone. Prefer `trash` instead.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/delete
  """
  @spec delete(String.t, String.t) :: {atom, String.t, String.t}
  def delete(user_id, message_id) do
    {:delete, base_url, "users/#{user_id}/messages/#{message_id}"}
  end

  @doc """
  Moves the specified message to the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/trash
  """
  @spec trash(String.t, String.t) :: {atom, String.t, String.t}
  def trash(user_id, message_id) do
    {:post, base_url, "users/#{user_id}/messages/#{message_id}/trash"}
  end

  @doc """
  Removes the specified message from the trash.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/untrash
  """
  @spec untrash(String.t, String.t) :: {atom, String.t, String.t}
  def untrash(user_id, message_id) do
    {:post, base_url, "users/#{user_id}/messages/#{message_id}/untrash"}
  end

  @doc """
  Searches for messages in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/list
  """
  @spec search(String.t, String.t, map) :: {atom, String.t, String.t}
  def search(user_id, query, params) when is_binary(query) do
    list(user_id, Map.put(params, :q, query))
  end

  @doc """
  Lists the messages in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/list
  """
  @spec list(String.t, map) :: {atom, String.t, String.t}
  def list(user_id, params) do
    available_options = [:max_results, :include_spam_trash, :label_ids, :page_token, :q]
    path = querify_params("users/#{user_id}/messages", available_options, params)
    {:get, base_url, path}
  end

  @doc """
  Converts a Gmail API message resource into a local struct.
  """
  @spec convert(map) :: Message.t
  def convert(message) do
    {payload, message} =
      message
      |> Helper.atomise_keys
      |> Map.pop(:payload)
    message = struct(Message, message)
    if payload, do: message = Map.put(message, :payload, Payload.convert(payload))
    message
  end

end
