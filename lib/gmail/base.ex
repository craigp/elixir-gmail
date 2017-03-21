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
      query =
        params
        |> Map.keys
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          string_key = Utils.camelize(key)
          val = if is_list(params[key]) do
            Enum.join(params[key], ",")
          else
            params[key]
          end
          Map.put(query, string_key, val)
        end)
      if Enum.empty?(query) do
        path
      else
        path <> "?" <> URI.encode_query(query)
      end
    end
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
