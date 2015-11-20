ExUnit.start

defmodule Gmail.OAuth2.ClientTest do

  use ExUnit.Case
  import Mock

  doctest Gmail.OAuth2.Client

  test "refreshes an expired access token" do
    fake_query = 'fake_query'
    opts = %Gmail.OAuth2.Opts{client_id: 'fake_client_id', client_secret: 'fake_client_secret', refresh_token: 'fake_refresh_token'}
    body = "{ \"access_token\": \"fake_access_token\", \"expires_in\": \"fake_expires_in\"}"
    response = %HTTPoison.Response{body: body}
    with_mock URI, [ encode_query: fn _query -> fake_query end ] do
      with_mock HTTPoison, [ post: fn _url, _headers -> {:ok, response} end ] do
        Gmail.OAuth2.Client.refresh_access_token(opts)
      end
    end
  end

end
