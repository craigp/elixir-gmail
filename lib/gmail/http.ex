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
  @spec execute(tuple, map) :: atom | {atom, map}

  def execute({:get, url, path}, %{access_token: access_token}) do
    (url <> path)
    |> HTTPoison.get(get_headers(access_token))
    |> do_parse_response
  end

  def execute({:post, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    (url <> path)
    |> HTTPoison.post(json, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:post, url, path}, %{access_token: access_token}) do
    (url <> path)
    |> HTTPoison.post("", get_headers(access_token))
    |> do_parse_response
  end

  def execute({:delete, url, path}, %{access_token: access_token}) do
    (url <> path)
    |> HTTPoison.delete(get_headers(access_token))
    |> do_parse_response
  end

  def execute({:put, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    (url <> path)
    |> HTTPoison.put(json, get_headers(access_token))
    |> do_parse_response
  end

  def execute({:patch, url, path, data}, %{access_token: access_token}) do
    {:ok, json} = encode(data)
    (url <> path)
    |> HTTPoison.patch(json, get_headers(access_token))
    |> do_parse_response
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec do_parse_response({atom, Response.t}) :: atom | {atom, map}
  defp do_parse_response({:ok, %Response{body: body}}) when byte_size(body) > 0 do
    decode(body)
  end

  defp do_parse_response({:ok, _response}) do
    :ok
  end

  defp do_parse_response({:error, %HTTPoison.Error{id: id, reason: reason}}) do
		{:error, reason}
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
