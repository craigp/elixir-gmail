defmodule Gmail.Draft do

  import Gmail.Base

  @moduledoc"""
  A draft email in the user's mailbox.
  """

  @doc """
  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts#resource
  """
  defstruct id: "",
    message: nil

  @type t :: %__MODULE__{}

  @doc """
  Lists the drafts in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/drafts/list
  """
  @spec list(String.t) :: {:ok, [Gmail.Draft.t]}
  def list(user_id  \\ "me") do
    case do_get("users/#{user_id}/drafts") do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"drafts" => raw_drafts}} ->
        {:ok, Enum.map(raw_drafts, &convert/1)}
    end
  end

  @spec convert(Map.t) :: Gmail.Draft.t
  defp convert(%{"id" => id,
    "message" => %{"id" => message_id, "threadId" => thread_id}}) do
    %Gmail.Draft{
      id: id,
      message: %Gmail.Message{id: message_id, thread_id: thread_id}
    }
  end

end

