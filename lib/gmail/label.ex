defmodule Gmail.Label do

  import Gmail.Base

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

  @spec get(String.t) :: Gmail.Label.t
  def get(id), do: get("me", id)

  @spec get(String.t, String.t) :: Gmail.Label.t
  def get(user_id, id) do
    case do_get("users/#{user_id}/labels/#{id}") do
      {:ok, %{"error" => %{"code" => 404}}} ->
        :not_found
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:error, details} ->
        {:error, details}
      {:ok, raw_label} ->
        {:ok, convert(raw_label)}
    end
  end

  @spec list(String.t) :: {:ok, [Gmail.Label.t]}
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
    "name" => name,
    "type" => type}) do
    %Gmail.Label{id: id, name: name, type: type}
  end

end
