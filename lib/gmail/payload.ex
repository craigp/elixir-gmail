defmodule Gmail.Payload do

  @moduledoc """
  Helper functions for dealing with email payloads.
  """

  alias __MODULE__
  alias Gmail.Body

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
    Enum.reduce(result, %Payload{}, fn({key, value}, payload) ->
      converted_value = case key do
        "body" ->
          Body.convert(value)
        "parts" ->
          Enum.map(value, &convert/1)
        _ ->
          value
      end
      %{payload | (Macro.underscore(key) |> String.to_atom) => converted_value}
    end)
  end

end
