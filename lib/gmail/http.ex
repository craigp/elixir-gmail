defmodule Gmail.HTTP do

  alias HTTPoison.Response
  import Poison, only: [decode: 1, encode: 1]

  @moduledoc """
  HTTP request handling.
  """

  @doc """
  Performs an HTTP POST request.
  """
  @spec post(String.t, String.t, map) :: {atom, map}
  def post(token, url, data) do
    with {:ok, headers} <- get_headers(token),
      {:ok, json} <- encode(data),
      {:ok, response} <- HTTPoison.post(url, json, headers),
      do: {:ok, parse_body(response)}
  end

  @doc """
  Performs an HTTP PUT request.
  """
  @spec put(String.t, String.t, map) :: {atom, map}
  def put(token, url, data) do
    with {:ok, headers} <- get_headers(token),
      {:ok, json} <- encode(data),
      {:ok, response} <- HTTPoison.put(url, json, headers),
      do: {:ok, parse_body(response)}
  end

  @doc """
  Performs an HTTP GET request.
  """
  @spec get(String.t, String.t) :: {atom, map}
  def get(token, url) do
    with {:ok, headers} <- get_headers(token),
      {:ok, response} <- HTTPoison.get(url, headers),
      do: {:ok, parse_body(response)}
  end

  @doc """
  Performs an HTTP DELETE request.
  """
  @spec delete(String.t, String.t) :: {atom, map}
  def delete(token, url) do
    with {:ok, headers} <- get_headers(token),
      {:ok, response} <- HTTPoison.delete(url, headers),
      do: {:ok, parse_body(response)}
  end

  @spec parse_body(Response.t) :: map
  defp parse_body(%Response{body: body}) do
    case decode(body) do
      {:ok, body} -> body
      {:error, _error} -> nil
    end
  end

  defp get_headers(token) do
    {:ok, [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]}
  end

end
