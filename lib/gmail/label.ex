defmodule Gmail.Label do

  @moduledoc"""
  Labels are used to categorize messages and threads within the user's mailbox.
  """

  import Gmail.Base

  @doc """
  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels#resource
  """
  defstruct id: "",
    name: "",
    messageListVisibility: "",
    labelListVisibility: "",
    type: "",
    messagesTotal: "",
    messagesUnread: "",
    threadsTotal: "",
    threadsUnread: ""

  @type t :: %__MODULE__{}

  @doc """
  Creates a new label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/create
  """
  @spec create(String.t, String.t) :: {atom, Gmail.Label.t}
  def create(name, user_id \\ "me") do
    case do_post("users/#{user_id}/labels", %{"name" => name}) do
      {:ok, %{"error" => %{"errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @doc """
  Updates the specified label.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/update
  """
  @spec update(Gmail.Label.t, String.t) :: {atom, Gmail.Label.t}
  def update(label, user_id \\ "me") do
    case do_put("users/#{user_id}/labels/#{label.id}", convert_for_update(label)) do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @doc """
  Immediately and permanently deletes the specified label and removes it from any messages and threads that it is applied to.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/delete
  """
  @spec delete(String.t, String.t) :: atom | {atom, String.t}
  def delete(label_id, user_id \\ "me") do
    case do_delete("users/#{user_id}/labels/#{label_id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        :not_found
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, _} ->
        :ok
    end
  end

  @doc """
  Gets the specified label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/get
  """
  @spec get(String.t | String.t, String.t) :: {atom, atom} | {atom, map} | {atom, Gmail.Label.t}
  def get(id, user_id \\ "me") do
    case do_get("users/#{user_id}/labels/#{id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @doc """
  Lists all labels in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/list
  """
  @spec list(String.t) :: {atom, [Gmail.Label.t]} | {atom, map}
  @spec list() :: {atom, [Gmail.Label.t]} | {atom, map}
  def list(user_id  \\ "me") do
    case do_get("users/#{user_id}/labels") do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"labels" => raw_labels}} ->
        {:ok, Enum.map(raw_labels, &convert/1)}
    end
  end

  @spec convert(map) :: Gmail.Label.t | nil
  defp convert(%{"id" => id,
    "labelListVisibility" => labelListVisibility,
    "messageListVisibility" => messageListVisibility,
    "name" => name,
    "type" => type}) do
    %Gmail.Label{id: id,
      name: name,
      labelListVisibility: labelListVisibility,
      messageListVisibility: messageListVisibility,
      type: type}
  end

  defp convert(%{"id" => id,
    "labelListVisibility" => labelListVisibility,
    "messageListVisibility" => messageListVisibility,
    "name" => name}) do
    %Gmail.Label{id: id,
      name: name,
      labelListVisibility: labelListVisibility,
      messageListVisibility: messageListVisibility}
  end

  defp convert(%{"id" => id,
    "name" => name,
    "type" => type}) do
    %Gmail.Label{id: id, name: name, type: type}
  end

  defp convert(_) do
    nil
  end

  @spec convert_for_update(Gmail.Label.t) :: map
  defp convert_for_update(%Gmail.Label{
    id: id,
    name: name,
    labelListVisibility: labelListVisibility,
    messageListVisibility: messageListVisibility
  }) do
    %{
      "id" => id,
      "name" => name,
      "labelListVisibility" => labelListVisibility,
      "messageListVisibility" => messageListVisibility
    }
  end

end
