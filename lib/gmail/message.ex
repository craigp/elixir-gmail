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

  def get(id), do: get("me", id)

  def get(user_id, id) do
    case do_get("users/#{user_id}/messages/#{id}?format=full") do
      {:ok, msg} ->
        Gmail.Message.convert(msg)
    end
  end

  def search(query), do: search("me", query)

  def search(user_id, query) do
    case do_get("users/#{user_id}/messages?q=#{query}") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
      not_ok -> not_ok
    end
  end

  def list(user_id \\ "me") do
    case do_get("users/#{user_id}/messages") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Gmail.Message{id: id, thread_id: thread_id} end)}
      not_ok -> not_ok
    end
  end

  def convert(%{"id" => id,
      "threadId" => thread_id,
      "labelIds" => label_ids,
      "snippet" => snippet,
      "historyId" => history_id,
      "payload" => payload,
      "sizeEstimate" => size_estimate
    }) do
  %Gmail.Message{id: id,
    thread_id: thread_id,
    label_ids: label_ids,
    snippet: snippet,
    history_id: history_id,
    payload: Gmail.Payload.convert(payload),
    size_estimate: size_estimate}
  end

end
