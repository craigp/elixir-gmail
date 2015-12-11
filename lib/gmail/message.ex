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

  @type t :: %__MODULE__{}

  @doc """
  Gets a message with the specified id
  """
  @spec get(String.t) :: {:ok, Gmail.Message.t}
  def get(id), do: get("me", id)

  @doc """
  Gets a message for the specified user with the specified id
  """
  @spec get(String.t, String.t) :: {:ok, Gmail.Message.t}
  def get(user_id, id) do
    case do_get("users/#{user_id}/messages/#{id}?format=full") do
      {:ok, msg} ->
        {:ok, convert(msg)}
    end
  end

  @doc """
  Searches for messages
  """
  @spec search(String.t, String.t) :: [Gmail.Message.t]
  def search(query), do: search("me", query)

  @doc """
  Searches for messages for the specified user
  """
  @spec search(String.t, String.t) :: [Gmail.Message.t]
  def search(user_id, query) do
    case do_get("users/#{user_id}/messages?q=#{query}") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(
          msgs, fn(%{"id" => id, "threadId" => thread_id}) ->
            %Gmail.Message{id: id, thread_id: thread_id}
          end)}
      not_ok ->
        {:error, not_ok}
    end
  end

  @doc """
  Gets a list of messages
  """
  @spec list(String.t) :: {:ok, [Gmail.Message.t]}
  def list(user_id \\ "me") do
    case do_get("users/#{user_id}/messages") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
      not_ok -> {:error, not_ok}
    end
  end

  @doc """
  Converts a Gmail API message response into a local struct
  """
  @spec convert(Map.t) :: Gmail.Message.t
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
