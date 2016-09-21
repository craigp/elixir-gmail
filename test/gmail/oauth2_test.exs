ExUnit.start

defmodule Gmail.OAuth2Test do

  use ExUnit.Case
  import Mock

  doctest Gmail.OAuth2

  test "refreshes an expired access token" do
    expires_in = 10
    access_token = "fake_access_token"
    fake_query = 'fake_query'
    opts = %{
      client_id: 'fake_client_id',
      client_secret: 'fake_client_secret',
    }
    body = "{ \"access_token\": \"#{access_token}\", \"expires_in\": #{expires_in}}"
    response = %HTTPoison.Response{body: body}
    with_mock URI, [ encode_query: fn _query -> fake_query end ] do
      with_mock HTTPoison, [ post: fn _url, _payload, _headers -> {:ok, response} end ] do
        {_access_token, _expires_at} = Gmail.OAuth2.refresh_access_token(opts)
      end
    end
  end

end
