defmodule Gmail.Draft do

  alias __MODULE__
  alias Gmail.Message

  @moduledoc"""
  A draft email in the user's mailbox.
  """

  import Gmail.Base

  @doc """
  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts#resource
  """
  defstruct id: "",
    message: nil

  @type t :: %__MODULE__{}

  @doc """
  Gets the specified draft.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/get
  """
  @spec get(String.t | String.t, String.t) :: {atom, Message.t} | {atom, String.t} | {atom, map}
  def get(id, user_id \\ "me") do
    case do_get("users/#{user_id}/drafts/#{id}?format=full") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_message} ->
        {:ok, convert(raw_message)}
    end
  end

  @doc """
  Lists the drafts in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/list
  """
  @spec list(String.t) :: {atom, [Draft.t]}
  def list(user_id  \\ "me") do
    case do_get("users/#{user_id}/drafts") do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"drafts" => raw_drafts}} ->
        {:ok, Enum.map(raw_drafts, &convert/1)}
    end
  end

  @spec convert(Map.t) :: Draft.t
  defp convert(%{"id" => id,
    "message" => %{"id" => message_id, "threadId" => thread_id}}) do
    %Gmail.Draft{
      id: id,
      message: %Message{id: message_id, thread_id: thread_id}
    }
  end

end

