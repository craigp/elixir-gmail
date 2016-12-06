defmodule Gmail.Utils do

  @moduledoc """
  General helper functions.
  """

  @doc """
  Converts a map with string keys to a map with atom keys
  """
  @spec atomise_keys(any) :: map
  def atomise_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, &atomise_key/2)
  end

  def atomise_keys(list) when is_list(list) do
    Enum.map(list, &atomise_keys/1)
  end

  def atomise_keys(not_a_map) do
    not_a_map
  end

  def atomise_key({key, val}, map) when is_binary(key) do
    key =
      key
      |> Macro.underscore
      |> String.to_atom
    atomise_key({key, val}, map)
  end

  def atomise_key({key, val}, map) do
    Map.put(map, key, atomise_keys(val))
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

  @doc """
  Loads the config value for a specified subject and key.
  """
  @spec load_config(atom, atom, any) :: any
  def load_config(subject, key, default) when is_atom(subject) and is_atom(key) do
    subject
    |> load_config
    |> Keyword.get(key, default)
  end

  @spec load_config(atom, atom) :: any
  def load_config(subject, key) when is_atom(subject) and is_atom(key) do
    load_config(subject, key, nil)
  end

  @spec load_config(atom) :: list
  def load_config(subject) do
    Application.get_env(:gmail, subject)
  end

  def extract_config(subject, category) do
    case Application.get_env(subject, category) do
      nil ->
        raise "No config for subject \"#{subject}\" in category \"#{category}\" #{Mix.env}"
      config ->
        Enum.into(config, %{})
    end
  end

  def extract_config(subject, category, key) do
    Keyword.get(Application.get_env(subject, category), key)
  end

end
