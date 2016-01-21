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
    token
      |> do_get_headers
      |> post_with_headers
      |> do_post(url, encode(data))
      |> do_parse_response
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
    token
      |> do_get_headers
      |> get_with_headers
      |> do_get(url)
      |> do_parse_response
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

  @spec get_headers(String.t) :: {atom, [{String.t, String.t}]}
  defp get_headers(token) do
    {:ok, do_get_headers(token)}
  end

  # --> private methods <--------------------------------------------------------------------------

  @spec do_parse_response({atom, Response.t}) :: {atom, map}
  defp do_parse_response({:ok, %Response{body: body}}) when byte_size(body) > 0 do
    decode(body)
  end

  defp do_parse_response({:ok, _response}) do
    nil
  end

  @spec do_get_headers(String.t) :: [{String.t, String.t}]
  defp do_get_headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  @spec get_with_headers(list(tuple)) :: (String.t -> Response.t)
  defp get_with_headers(headers) do
    fn(url) -> HTTPoison.get(url, headers) end
  end

  @spec post_with_headers(list(tuple)) :: (String.t, String.t -> Response.t)
  defp post_with_headers(headers) do
    fn(url, json) -> HTTPoison.post(url, json, headers) end
  end

  @spec do_get((String.t -> Response.t), String.t) :: Response.t
  defp do_get(fun, url) do
    fun.(url)
  end

  @spec do_post((String.t, String.t -> Response.t), String.t, {atom, String.t}) :: Response.t
  defp do_post(fun, url, {:ok, json}) do
    fun.(url, json)
  end

end
