ExUnit.start

defmodule Gmail.OAuth2.ClientTest do

  use ExUnit.Case
  import Mock
  use Timex

  doctest Gmail.OAuth2.Client

  test "refreshes an expired access token" do
    expected_result = {:ok,
      %Gmail.OAuth2.Opts{access_token: "fake_access_token",
        client_id: 'fake_client_id', client_secret: 'fake_client_secret',
        expires_at: 1448039712, refresh_token: 'fake_refresh_token',
        token_type: "Bearer", user_id: ""}}
    fake_query = 'fake_query'
    opts = %Gmail.OAuth2.Opts{client_id: 'fake_client_id', client_secret: 'fake_client_secret', refresh_token: 'fake_refresh_token'}
    body = "{ \"access_token\": \"fake_access_token\", \"expires_in\": 10}"
    response = %HTTPoison.Response{body: body}
    with_mock URI, [ encode_query: fn _query -> fake_query end ] do
      with_mock HTTPoison, [ post: fn _url, _payload, _headers -> {:ok, response} end ] do
        assert expected_result = Gmail.OAuth2.Client.refresh_access_token(opts)
      end
    end
  end

end
