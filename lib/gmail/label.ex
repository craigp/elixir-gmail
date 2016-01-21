defmodule Gmail.Label do

  @moduledoc"""
  Labels are used to categorize messages and threads within the user's mailbox.
  """

  alias __MODULE__
  import Gmail.Base

  @doc """
  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels#resource
  """
  defstruct id: nil,
    name: nil,
    message_list_visibility: nil,
    label_list_visibility: nil,
    type: nil,
    messages_total: nil,
    messages_unread: nil,
    threads_total: nil,
    threads_unread: nil

  @type t :: %__MODULE__{}

  @doc """
  Creates a new label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/create
  """
  @spec create(String.t, String.t) :: {atom, Label.t}
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
  @spec update(Label.t, String.t) :: {atom, Label.t}
  def update(label, user_id \\ "me") do
    case do_put("users/#{user_id}/labels/#{label.id}", convert_for_update(label)) do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  # @doc """
  # Updates the specified label. This method supports patch semantics.

  # Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/patch
  # """
  # @spec patch(Label.t, String.t) :: {atom, Label.t}
  # def patch(label, user_id \\ "me") do
  #   case do_patch("users/#{user_id}/labels/#{label.id}", convert_for_update(label)) do
  #     {:ok, %{"error" => details}} ->
  #       {:error, details}
  #     {:ok, raw_label} ->
  #       {:ok, convert(raw_label)}
  #   end
  # end

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
  @spec get(String.t | String.t, String.t) :: {atom, atom} | {atom, map} | {atom, Label.t}
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
  @spec list(String.t) :: {atom, [Label.t]} | {atom, map}
  @spec list() :: {atom, [Label.t]} | {atom, map}
  def list(user_id  \\ "me") do
    case do_get("users/#{user_id}/labels") do
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, %{"labels" => raw_labels}} ->
        {:ok, Enum.map(raw_labels, &convert/1)}
    end
  end

  @spec convert(map) :: Label.t
  defp convert(result) do
    Enum.reduce(result, %Label{}, fn({key, value}, label) ->
      %{label | (key |> Macro.underscore |> String.to_atom) => value}
    end)
  end

  @spec convert_for_update(Label.t) :: map
  defp convert_for_update(%Label{
    id: id,
    name: name,
    label_list_visibility: label_list_visibility,
    message_list_visibility: message_list_visibility
  }) do
    %{
      "id" => id,
      "name" => name,
      "labelListVisibility" => label_list_visibility,
      "messageListVisibility" => message_list_visibility
    }
  end

end
