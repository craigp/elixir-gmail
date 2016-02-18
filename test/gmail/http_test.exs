ExUnit.start

defmodule Gmail.HTTPTest do

  use ExUnit.Case
  import Mock

  setup do

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    {:ok,
      access_token_rec: access_token_rec
    }
  end

  test "performs a GET request and parses the output", context do
    url = "http://nothing.com"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ get: fn _url, _headers -> {:ok, response} end ] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.get(url)
      end
    end
  end

  test "performs a POST request and parses the output", context do
    data = %{"some" => "stuff"}
    url = "http://nothing.com"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ post: fn _url, _data, _headers -> {:ok, response} end ] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.post(url, data)
      end
    end
  end

  test "performs a PUT request and parses the output", context do
    data = %{"some" => "stuff"}
    url = "http://nothing.com"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ put: fn _url, _data, _headers -> {:ok, response} end ] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.put(url, data)
      end
    end
  end

  test "performs a PATCH request and parses the output", context do
    data = %{"some" => "stuff"}
    url = "http://nothing.com"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ patch: fn _url, _data, _headers -> {:ok, response} end ] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.patch(url, data)
      end
    end
  end

  test "Performs a DELETE request and parses the output", context do
    url = "http://nothing.com"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ delete: fn _url, _headers -> {:ok, response} end ] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.delete(url)
      end
    end
  end

end
