defmodule Gmail.Base do

  @base_url "https://www.googleapis.com/gmail/v1/"

  @moduledoc """
  Base class for common functionality.
  """

  def base_url, do: @base_url

  @doc """
  Performs an HTTP GET request.
  """
  @spec do_get(String.t) :: {atom, Map.t}
  def do_get(path) do
    get_access_token |> Gmail.HTTP.get(base_url <> path)
  end

  @doc """
  Performs an HTTP POST request.
  """
  @spec do_post(String.t, Map.t) :: {atom, Map.t}
  def do_post(path, data) do
    get_access_token |> Gmail.HTTP.post(base_url <> path, data)
  end

  @doc """
  Performs an HTTP PUT request.
  """
  @spec do_put(String.t, Map.t) :: {atom, Map.t}
  def do_put(path, data) do
    get_access_token |> Gmail.HTTP.put(base_url <> path, data)
  end

  @doc """
  Performs an HTTP DELETE reauest.
  """
  @spec do_delete(String.t) :: {atom, Map.t}
  def do_delete(path) do
    get_access_token |> Gmail.HTTP.delete(base_url <> path)
  end

  defp get_access_token do
    %{access_token: access_token} = Gmail.OAuth2.get_config
    access_token
  end

end
