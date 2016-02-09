defmodule Gmail.Payload do

  @moduledoc """
  Helper functions for dealing with email payloads.
  """

  alias __MODULE__
  alias Gmail.{Body, Helper}

  defstruct part_id: "",
    mime_type: "",
    filename: "",
    headers: [],
    body: %Body{},
    parts: []

  @type t :: %__MODULE__{}

  @doc """
  Converts an email payload.
  """
  @spec convert(map) :: Payload.t
  def convert(result) do
    payload = Helper.atomise_keys(result)
    {body, payload} =
      result
      |> Helper.atomise_keys
      |> Map.pop(:body)
    {parts, payload} = Map.pop(payload, :parts)
    payload = struct(Payload, payload)
    if body, do: payload = Map.put(payload, :body, Body.convert(body))
    if parts do
      parts = Enum.map(parts, &convert/1)
      payload = Map.put(payload, :parts, parts)
    end
    payload
  end

end
