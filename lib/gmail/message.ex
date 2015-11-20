defmodule Gmail.Message do

  import Gmail.Base

  defstruct id: "",
  thread_id: "",
  label_ids: [],
  snippet: "",
  history_id: nil,
  payload: %Gmail.Payload{},
  size_estimate: nil,
  raw: ""

  @doc """
  Gets a message
  """
  def get(id), do: get("me", id)

  @doc """
  Gets a message
  """
  def get(user_id, id) do
    case do_get("users/#{user_id}/messages/#{id}?format=full") do
      {:ok, msg} ->
        convert(msg)
    end
  end

  @doc """
  Searches for messages
  """
  def search(query), do: search("me", query)

  @doc """
  Searches for messages
  """
  def search(user_id, query) do
    case do_get("users/#{user_id}/messages?q=#{query}") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
        not_ok -> not_ok
    end
  end

  @doc """
  Gets a list of messages
  """
  def list(user_id \\ "me") do
    case do_get("users/#{user_id}/messages") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
        not_ok -> not_ok
    end
  end

  @doc """
  Converts a Gmail API message response into a local struct
  """
  def convert(%{"id" => id,
    "threadId" => thread_id,
    "labelIds" => label_ids,
    "snippet" => snippet,
    "historyId" => history_id,
    "payload" => payload,
    "sizeEstimate" => size_estimate}) do
    %Gmail.Message{id: id,
      thread_id: thread_id,
      label_ids: label_ids,
      snippet: snippet,
      history_id: history_id,
      payload: Gmail.Payload.convert(payload),
      size_estimate: size_estimate}
  end

end
