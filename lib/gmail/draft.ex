defmodule Gmail.Draft do

  @moduledoc"""
  A draft email in the user's mailbox.
  """

  alias __MODULE__
  alias Gmail.{Message, Thread}
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

  @doc """
  Immediately and permanently deletes the specified draft. Does not simply trash it.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/delete
  """
  @spec delete(String.t) :: {atom, atom} | atom
  def delete(id, user_id \\ "me") do
    case do_delete("users/#{user_id}/drafts/#{id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      nil ->
        :ok
    end
  end

  @doc """
  Sends the specified, existing draft to the recipients in the `To`, `Cc`, and `Bcc` headers.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/send
  """
  @spec send(String.t) :: {atom, Thread.t}
  def send(id, user_id \\ "me") do
    case do_post("users/#{user_id}/drafts/send", %{"id" => id}) do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => detail}} ->
        {:error, detail}
      {:ok, %{"threadId" => thread_id}} ->
        {:ok, %{thread_id: thread_id}}
    end
  end

  @spec convert(map) :: Draft.t
  defp convert(%{"id" => id,
    "message" => %{"id" => message_id, "threadId" => thread_id}}) do
    %Draft{
      id: id,
      message: %Message{id: message_id, thread_id: thread_id}
    }
  end

end

