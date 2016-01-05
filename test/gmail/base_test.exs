ExUnit.start

defmodule Gmail.BaseTest do

  use ExUnit.Case
  import Mock

  test "gets the config from the OAuth2 client and makes a GET request" do
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, "foo" } end] do
      with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
        Gmail.Base.do_get(some_url)
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(access_token, Gmail.Base.base_url <> some_url)
      end
    end
  end

  test "gets the config from the OAuth2 client and makes a POST request" do
    data = %{"some" => "stuff"}
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    with_mock Gmail.HTTP, [ post: fn _at, _url, _data -> { :ok, "foo" } end] do
      with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
        Gmail.Base.do_post(some_url, data)
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.post(access_token, Gmail.Base.base_url <> some_url, data)
      end
    end
  end

end
