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
  @spec get(String.t, String.t) :: {atom, Message.t} | {atom, String.t} | {atom, map}
  def get(user_id, draft_id) do
    {:get, base_url, "users/#{user_id}/drafts/#{draft_id}"}
  end

  @doc """
  Lists the drafts in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/list
  """
  @spec list(String.t) :: {atom, [Draft.t]}
  def list(user_id) do
    {:get, base_url, "users/#{user_id}/drafts"}
  end

  @doc """
  Immediately and permanently deletes the specified draft. Does not simply trash it.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/delete
  """
  @spec delete(String.t, String.t) :: {atom, atom} | atom
  def delete(user_id, draft_id) do
    {:delete, base_url, "users/#{user_id}/drafts/#{draft_id}"}
  end

  @doc """
  Sends the specified, existing draft to the recipients in the `To`, `Cc`, and `Bcc` headers.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/send
  """
  @spec send(String.t, String.t) :: {atom, Thread.t}
  def send(user_id, draft_id) do
    {:post, base_url, "users/#{user_id}/drafts/send", %{"id" => draft_id}}
  end

  @spec convert(map) :: Draft.t
  def convert(%{"id" => id,
    "message" => %{"id" => message_id, "threadId" => thread_id}}) do
    %Draft{
      id: id,
      message: %Message{id: message_id, thread_id: thread_id}
    }
  end

end

