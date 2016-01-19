defmodule Gmail.HTTP do

  @moduledoc """
  HTTP request handling.
  """

  alias HTTPoison.Response
  import Poison, only: [decode: 1, encode: 1]

  @doc """
  Performs an HTTP POST request.
  """
  @spec post(String.t, String.t, map) :: {atom, map}
  def post(token, url, data) do
    with {:ok, headers} <- get_headers(token),
      {:ok, json} <- encode(data),
      {:ok, %Response{body: body}} <- HTTPoison.post(url, json, headers),
      {:ok, json} <- decode(body),
      do: {:ok, json}
  end

  @doc """
  Performs an HTTP PUT request.
  """
  @spec put(String.t, String.t, map) :: {atom, map}
  def put(token, url, data) do
    with {:ok, headers} <- get_headers(token),
      {:ok, json} <- encode(data),
      {:ok, %Response{body: body}} <- HTTPoison.put(url, json, headers),
      {:ok, response_json} <- decode(body),
      do: {:ok, response_json}
  end

  @doc """
  Performs an HTTP GET request.
  """
  @spec get(String.t, String.t) :: {atom, map}
  def get(token, url) do
    token |> do_get_headers |> get_with_headers |> do_get(url) |> do_parse_response
    # with {:ok, headers} <- get_headers(token),
    #   {:ok, %Response{body: body}} <- HTTPoison.get(url, headers),
    #   {:ok, json} <- decode(body),
    #   do: {:ok, json}
  end

  @doc """
  Performs an HTTP DELETE request.
  """
  @spec delete(String.t, String.t) :: {atom, map}
  def delete(token, url) do
    with {:ok, headers} <- get_headers(token),
      {:ok, %Response{body: body}} <- HTTPoison.delete(url, headers),
      {:ok, json} <- decode(body),
      do: {:ok, json}
  end

  @spec get_headers(String.t) :: {atom, map}
  defp get_headers(token) do
    {:ok, do_get_headers(token)}
  end

  ## EXPERIMENTAL ############################################################

  defp do_parse_response({:ok, %Response{body: body}}) when byte_size(body) > 0 do
    case decode(body) do
      {:ok, decoded} ->
        {:ok, decoded}
      {:error, _error} ->
        nil
    end
  end

  defp do_parse_response({:ok, _response}) do
    nil
  end

  # TODO how should I handle errors? Should I, or should I just let it fail?
  # {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}
  defp do_parse_response(some_other_shit) do
    IO.inspect some_other_shit
    nil
  end

  defp do_get_headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp get_with_headers(headers) do
    fn(url) -> HTTPoison.get(url, headers) end
  end

  defp do_get(fun, url) do
    fun.(url)
  end

end
