defmodule Gmail.Threads do

  # https://developers.google.com/gmail/api/v1/reference/users/threads/list

  @base_url "https://www.googleapis.com/gmail/v1"

  def list(user_id) do
    url = "#{@base_url}/users/#{user_id}/threads"
    token = Gmail.XOAuth2.Client.generate_token(Gmail.XOAuth2.Opts.from_config)
    Gmail.HTTP.get(token, url)
  end

end
