defmodule Gmail.Base do

  def base_url, do: "https://www.googleapis.com/gmail/v1/"

  @doc """
  Performs an HTTP get request
  """
  def do_get(path) do
    %{access_token: access_token} = Gmail.OAuth2.Client.get_config
    Gmail.HTTP.get(access_token, base_url <> path)
  end

end
