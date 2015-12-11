defmodule Gmail.Base do

  @base_url "https://www.googleapis.com/gmail/v1/"

  @moduledoc """
  Base class for common functionality.
  """

  def base_url, do: @base_url

  @doc """
  Performs an HTTP get request.
  """
  @spec do_get(String.t) :: {:ok, Map.t}
  def do_get(path) do
    %{access_token: access_token} = Gmail.OAuth2.get_config
    Gmail.HTTP.get(access_token, base_url <> path)
  end

end
