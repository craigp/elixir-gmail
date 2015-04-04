defmodule Gmail.Base do

  def base_url, do: "https://www.googleapis.com/gmail/v1/"

  def do_get(url) do
    %{access_token: access_token} = Gmail.XOAuth2.Client.get_config
    Gmail.HTTP.get(access_token, base_url <> url)
  end

end
