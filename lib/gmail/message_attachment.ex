defmodule Gmail.MessageAttachment do

  @moduledoc """
  An email message attachment.
  """

  alias __MODULE__
  alias Gmail.Utils
  import Gmail.Base

  @doc """
  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/attachments
  """
  defstruct attachmentId: "",
    size: 0,
    data: ""

  @type t :: %__MODULE__{}

  @doc """
  Gets the specified attachment.

  Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/messages/attachments/get
  """
  @spec get(String.t, String.t, String.t) :: {atom, String.t, String.t}
  def get(user_id, message_id, id) do
    path = querify_params("users/#{user_id}/messages/#{message_id}/attachments/#{id}", [], %{})
    {:get, base_url, path}
  end

  @doc """
  Converts a Gmail API attachment resource into a local struct.
  """
  @spec convert(map) :: MessageAttachment.t
  def convert(message) do
    attachment = message |> Utils.atomise_keys
    struct(MessageAttachment, attachment)
  end

  @doc """
  Handles an attachment resource response from the Gmail API.
  """
  def handle_attachment_response(response) do
    response
    |> handle_error
    |> case do
      {:error, message} ->
        {:error, message}
      {:ok, raw_message} ->
        {:ok, MessageAttachment.convert(raw_message)}
    end
  end

end
