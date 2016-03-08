defmodule Gmail.Helper do

  @moduledoc """
  General helper functions.
  """

  @doc """
  Converts a map with string keys to a map with atom keys
  """
  @spec atomise_keys(map) :: map
  def atomise_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, val}, map ->
      Map.put(map, (key |> Macro.underscore |> String.to_atom), val)
    end)
  end

  @doc """
  Camelizes a string (with the first letter in lower case)
  """
  def camelize(str) when is_atom(str) do
    str |> Atom.to_string |> camelize
  end

  def camelize(str) do
    [first|rest] = str |> Macro.camelize |> String.codepoints
    [String.downcase(first)|rest] |> Enum.join
  end

end
