defmodule Gmail.HTTP do

  @moduledoc """
  HTTP request handling.
  """

  import Poison, only: [decode: 1, encode: 1]
  alias HTTPoison.Response

  #  Client API {{{ #

  @doc """
  Executes an HTTP action based on the command provided.
  """
  @spec execute(tuple, map) :: nil | {atom, map}

  def execute({:get, url, path}, %{access_token: access_token}) do
    HTTPoison.get(url <> path, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:post, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    HTTPoison.post(url <> path, json, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:post, url, path}, %{access_token: access_token}) do
    HTTPoison.post(url <> path, "", get_headers(access_token))
    |> do_parse_response
  end

  def execute({:delete, url, path}, %{access_token: access_token}) do
    HTTPoison.delete(url <> path, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:put, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    HTTPoison.put(url <> path, json, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:patch, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    HTTPoison.patch(url <> path, json, get_headers(access_token))
    |> do_parse_response
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec do_parse_response({atom, Response.t}) :: {atom, map}
  defp do_parse_response({:ok, %Response{body: body}}) when byte_size(body) > 0 do
    decode(body)
  end

  defp do_parse_response({:ok, _response}) do
    :ok
  end

  @spec get_headers(String.t) :: [{String.t, String.t}]
  defp get_headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  #  }}} Private functions #

end
