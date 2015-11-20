ExUnit.start

defmodule Gmail.BaseTest do

  use ExUnit.Case
  import Mock

  test "gets the config from the OAuth2 client" do
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, "foo" } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> access_token_rec end ] do
        Gmail.Base.do_get(some_url)
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(access_token, Gmail.Base.base_url <> some_url)
      end
    end
  end

end
