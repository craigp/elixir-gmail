defmodule Gmail.HTTP do

  @moduledoc """
  HTTP request handling.
  """

  use GenServer
  import Poison, only: [decode: 1, encode: 1]
  alias HTTPoison.Response
  alias Gmail.OAuth2

  #  Server API {{{ #

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  @spec handle_call({atom, String.t}, pid, map) :: {atom, map, map}
  def handle_call({:get, url}, _from, state) do
    %{access_token: token} = OAuth2.get_config
    result =
      token
      |> do_get_headers
      |> get_with_headers
      |> do_get(url)
      |> do_parse_response
    {:reply, result, state}
  end

  def handle_call({:post, url, data}, _from, state) do
    %{access_token: token} = OAuth2.get_config
    result =
      token
      |> do_get_headers
      |> post_with_headers
      |> do_post(url, encode(data))
      |> do_parse_response
    {:reply, result, state}
  end

  #  }}} Server API #

  @doc """
  Performs an HTTP POST request.
  """
  @spec post(String.t, map) :: {atom, map}
  def post(url, data) do
    GenServer.call(__MODULE__, {:post, url, data})
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
  Performs an HTTP PATCH request.
  """
  @spec patch(String.t, String.t, map) :: {atom, map}
  def patch(token, url, data) do
    with {:ok, headers} <- get_headers(token),
      {:ok, json} <- encode(data),
      {:ok, %Response{body: body}} <- HTTPoison.patch(url, json, headers),
      {:ok, response_json} <- decode(body),
      do: {:ok, response_json}
  end

  @doc """
  Performs an HTTP GET request.
  """
  @spec get(String.t) :: {atom, map}
  def get(url) do
    GenServer.call(__MODULE__, {:get, url})
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

  #  Private functions {{{ #

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

  #  }}} Private functions #

end
