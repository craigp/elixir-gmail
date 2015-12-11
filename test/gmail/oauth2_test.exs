ExUnit.start

defmodule Gmail.OAuth2Test do

  use ExUnit.Case
  import Mock
  use Timex

  doctest Gmail.OAuth2

  test "refreshes an expired access token" do
    expires_in = 10
    expected_result = %Gmail.OAuth2{
      access_token: "fake_access_token",
      client_id: 'fake_client_id',
      client_secret: 'fake_client_secret',
      expires_at: (Date.to_secs(Date.now) + expires_in),
      refresh_token: 'fake_refresh_token',
      token_type: "Bearer", user_id: ""}
    fake_query = 'fake_query'
    opts = %Gmail.OAuth2{
      client_id: 'fake_client_id',
      client_secret: 'fake_client_secret',
      refresh_token: 'fake_refresh_token'}
    body = "{ \"access_token\": \"fake_access_token\", \"expires_in\": 10}"
    response = %HTTPoison.Response{body: body}
    with_mock URI, [ encode_query: fn _query -> fake_query end ] do
      with_mock HTTPoison, [ post: fn _url, _payload, _headers -> {:ok, response} end ] do
        {:ok, result} = Gmail.OAuth2.refresh_access_token(opts)
        assert expected_result.access_token == result.access_token
        assert expected_result.client_id == result.client_id
        assert expected_result.client_secret == result.client_secret
        assert expected_result.refresh_token == result.refresh_token
      end
    end
  end

end

