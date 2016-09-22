defmodule Gmail.Payload do

  @moduledoc """
  Helper functions for dealing with email payloads.
  """

  alias __MODULE__
  alias Gmail.{MessageAttachment, Helper}

  defstruct part_id: "",
    mime_type: "",
    filename: "",
    headers: [],
    body: %MessageAttachment{},
    parts: []

  @type t :: %__MODULE__{}

  @doc """
  Converts an email payload.
  """
  @spec convert(map) :: Payload.t
  def convert(result) do
    {body, payload} =
      result
      |> Helper.atomise_keys
      |> Map.pop(:body)
    {parts, payload} = Map.pop(payload, :parts)
    payload = struct(Payload, payload)
    payload = if body, do: Map.put(payload, :body, MessageAttachment.convert(body)), else: payload
    payload = if parts do
      parts = Enum.map(parts, &convert/1)
      Map.put(payload, :parts, parts)
    else
      payload
    end
    payload
  end

end
