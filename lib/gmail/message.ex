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
  @spec get(String.t | String.t, String.t) :: {atom, Message.t} | {atom, String.t} | {atom, map}
  def get(user_id, message_id) do
    {:get, base_url, "users/#{user_id}/messages/#{message_id}?format=full"}
    # case do_get("users/#{user_id}/messages/#{id}?format=full") do
    #   {:ok, %{"error" => %{"code" => 404}}} ->
    #     {:error, :not_found}
    #   {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
    #     [%{"message" => error_message}|_rest] = errors
    #     {:error, error_message}
    #   {:ok, %{"error" => details}} ->
    #     {:error, details}
    #   {:ok, raw_message} ->
    #     {:ok, convert(raw_message)}
    # end
  end

  @doc """
  Searches for messages in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/list
  """
  @spec search(String.t | String.t, String.t) :: {atom, [Message.t]}
  def search(query, user_id \\ "me") do
    case do_get("users/#{user_id}/messages?q=#{query}") do
      {:ok, %{"messages" => msgs}} ->
        {:ok, Enum.map(
          msgs, fn(%{"id" => id, "threadId" => thread_id}) ->
            %Message{id: id, thread_id: thread_id}
          end)}
    end
  end

  @doc """
  Lists the messages in the user's mailbox.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/list
  """
  @spec list(String.t) :: {atom, [Message.t]}
  def list(user_id \\ "me") do
    {:get, base_url, "users/#{user_id}/messages"}
    # case do_get("users/#{user_id}/messages") do
    #   {:ok, %{"messages" => msgs}} ->
    #     {:ok, Enum.map(msgs, fn(%{"id" => id, "threadId" => thread_id}) -> %Message{id: id, thread_id: thread_id} end)}
    # end
  end

  @doc """
  Converts a Gmail API message resource into a local struct
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
