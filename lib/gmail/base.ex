defmodule Gmail.Base do

  @moduledoc """
  Base class for common functionality.
  """

  alias Gmail.Utils

  @default_base_url "https://www.googleapis.com/gmail/v1/"

  @doc """
  Gets the base URL for Gmail API requests
  """
  @spec base_url() :: String.t
  def base_url do
    case Application.fetch_env(:gmail, :api) do
      {:ok, %{url: url}} ->
        url
      {:ok, api_config} ->
        Application.put_env(:gmail, :api, Map.put(api_config, :url, @default_base_url))
        base_url()
      :error ->
        Application.put_env(:gmail, :api, %{url: @default_base_url})
        base_url()
    end
  end

  @spec querify_params(String.t, list, map) :: String.t
  def querify_params(path, available_options, params) do
    if Enum.empty?(params) do
      path
    else
      {query, list_params} =
        params
        |> Enum.reduce({ Map.new, Map.new}, fn {key, value}, {q, lps} ->
            if key in available_options do
              string_key = Utils.camelize(key)
              if is_list(value) do
                {q, Map.put(lps, string_key, value)}
              else
                {Map.put(q, string_key, value), lps}
              end
            else
              {q, lps}
            end
          end)
      if Enum.empty?(query) && Enum.empty?(list_params) do
        path
      else
        path <> "?" <> URI.encode_query(query) <> queryify_arrays(list_params)
      end
    end
  end

  @spec queryify_arrays(map) :: String.t
  defp queryify_arrays(params) do
        params
        |> Map.keys
        |> Enum.reduce("", fn key, query_string ->
            string_key = "&" <> key <> "="
            query_string <> string_key <> Enum.join(params[key], string_key)
           end)
        |> URI.encode
  end

  @spec handle_error({atom, map}) :: {atom, String.t} | {atom, map}
  @spec handle_error({atom, String.t}) :: {atom, String.t} | {atom, map}
  def handle_error(response) do
    case response do
      {:ok, %{"error" => %{"code" => 404}}} ->
        {:error, :not_found}
      {:ok, %{"error" => %{"code" => 400, "errors" => errors}}} ->
        [%{"message" => error_message}|_rest] = errors
        {:error, error_message}
      {:ok, %{"error" => details}} ->
        {:error, details}
      {:ok, other} ->
        {:ok, other}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
