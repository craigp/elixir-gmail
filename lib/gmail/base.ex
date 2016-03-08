defmodule Gmail.Base do

  @moduledoc """
  Base class for common functionality.
  """

  alias Gmail.{HTTP}

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
        api_config = %{api_config | url: @default_base_url}
        base_url
      :error ->
        Application.put_env(:gmail, :api, %{url: @default_base_url})
        base_url
    end
  end

end
