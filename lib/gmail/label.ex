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
  @spec create(String.t, String.t) :: {atom, String.t, String.t, map}
  def create(user_id, label_name) do
    {:post, base_url, "users/#{user_id}/labels", %{"name" => label_name}}
  end

  @doc """
  Updates the specified label.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/update
  """
  @spec update(String.t, Label.t) :: {atom, String.t, String.t, map}
  def update(user_id, %Label{id: id} = label) do
    {:put, base_url, "users/#{user_id}/labels/#{id}", convert_for_update(label)}
  end

  @doc """
  Updates the specified label. This method supports patch semantics.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/patch
  """
  @spec patch(String.t, Label.t) :: {atom, String.t, String.t, map}
  def patch(user_id, %Label{id: id} = label) do
    {:patch, base_url, "users/#{user_id}/labels/#{id}", convert_for_patch(label)}
  end

  @doc """
  Immediately and permanently deletes the specified label and removes it from any messages and threads that it is applied to.

  Google API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/delete
  """
  @spec delete(String.t, String.t) :: {atom, String.t, String.t}
  def delete(user_id, label_id) do
    {:delete, base_url, "users/#{user_id}/labels/#{label_id}"}
  end

  @doc """
  Gets the specified label.

  > Gmail API documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/get
  """
  @spec get(String.t, String.t) :: {atom, String.t, String.t}
  def get(user_id, label_id) do
    {:get, base_url, "users/#{user_id}/labels/#{label_id}"}
  end

  @doc """
  Lists all labels in the user's mailbox.

  > Gmail API Documentation: https://developers.google.com/gmail/api/v1/reference/users/labels/list
  """
  @spec list(String.t) :: {atom, String.t, String.t}
  def list(user_id) do
    {:get, base_url, "users/#{user_id}/labels"}
  end

  @doc """
  Converts a Gmail API label resource into a local struct.
  """
  @spec convert(map) :: Label.t
  def convert(result) do
    Enum.reduce(result, %Label{}, fn({key, value}, label) ->
      %{label | (key |> Macro.underscore |> String.to_atom) => value}
    end)
  end

  @spec convert_for_patch(Label.t) :: map
  defp convert_for_patch(label) do
    label |> Map.from_struct |> Enum.reduce(%{}, fn({key, value}, map) ->
      if value do
        {first_letter, rest} = key |> Atom.to_string |> Macro.camelize |> String.split_at(1)
        Map.put(map, String.downcase(first_letter) <> rest, value)
      else
        map
      end
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
