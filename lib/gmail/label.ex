defmodule Gmail.Label do

  import Gmail.Base

  @moduledoc"""
  Labels are used to categorize messages and threads within the user's mailbox.
  """

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
  @spec create(String.t, String.t) :: {:ok, Gmail.Label.t}
  def create(name, user_id \\ "me") do
    case do_post("users/#{user_id}/labels", %{"name" => name}) do
      {:ok, %{"error" => %{"errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:error, details} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @doc """
  Updates the specified label.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/update
  """
  @spec update(Gmail.Label.t, String.t) :: {:ok, Gmail.Label.t}
  @spec update(Gmail.Label.t, String.t) :: {:error, any}
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
  @spec delete(String.t, String.t) :: {atom, any} # not sure any is a good idea
  def delete(label_id, user_id \\ "me") do
    case do_delete("users/#{user_id}/labels/#{label_id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        :not_found
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, nil} ->
        :ok
    end
  end

  @doc """
  Gets the specified label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/get
  """
  @spec get(String.t) :: atom
  @spec get(String.t) :: {atom, Gmail.Label.t}
  @spec get(String.t) :: {atom, String.t}
  def get(id), do: get("me", id)

  @doc """
  Gets the specified label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/get
  """
  @spec get(String.t) :: atom
  @spec get(String.t) :: {atom, Gmail.Label.t}
  @spec get(String.t) :: {atom, String.t}
  def get(user_id, id) do
    case do_get("users/#{user_id}/labels/#{id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        :not_found
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:error, details} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @doc """
  Lists all labels in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/list
  """
  @spec list(String.t) :: {:ok, [Gmail.Label.t]}
  @spec list(String.t) :: {:error, any}
  def list(user_id  \\ "me") do
    case do_get("users/#{user_id}/labels") do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"labels" => raw_labels}} ->
        {:ok, Enum.map(raw_labels, &convert/1)}
    end
  end

  @spec convert(Map.t) :: Gmail.Label.t
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

  @spec convert(Map.t) :: Gmail.Label.t
  defp convert(%{"id" => id,
    "labelListVisibility" => labelListVisibility,
    "messageListVisibility" => messageListVisibility,
    "name" => name}) do
    %Gmail.Label{id: id,
      name: name,
      labelListVisibility: labelListVisibility,
      messageListVisibility: messageListVisibility}
  end

  @spec convert(Map.t) :: Gmail.Label.t
  defp convert(%{"id" => id,
    "name" => name,
    "type" => type}) do
    %Gmail.Label{id: id, name: name, type: type}
  end

  @spec convert_for_update(Gmail.Label.t) :: Map.t
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
