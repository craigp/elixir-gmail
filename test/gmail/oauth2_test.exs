ExUnit.start

defmodule Gmail.OAuth2Test do

  use ExUnit.Case
  import Mock

  doctest Gmail.OAuth2

  # TODO use bypass instead of a mock
  test "refreshes an expired access token" do
    expires_in = 10
    access_token = "fake_access_token"
    body = "{ \"access_token\": \"#{access_token}\", \"expires_in\": #{expires_in}}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ post: fn _url, _payload, _headers -> {:ok, response} end ] do
      {:ok, {access_token2, _}} = Gmail.OAuth2.refresh_access_token("fake-refresh-token")
      assert access_token2 == access_token
    end
  end

end
