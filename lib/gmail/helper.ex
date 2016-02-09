defmodule Gmail.Helper do

  @doc """
  Converts a map with string keys to a map with atom keys
  """
  def atomise_keys(map) do
    Enum.reduce(map, %{}, fn {key, val}, map ->
      Map.put(map, (key |> Macro.underscore |> String.to_atom), val)
    end)
  end

end
