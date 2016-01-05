ExUnit.start

defmodule Gmail.HTTPTest do

  use ExUnit.Case
  import Mock

  test "performs a GET request and parses the output" do
    url = "http://nothing.com"
    token = "some_token"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ get: fn _url, _headers -> {:ok, response} end ] do
      assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.get(token, url)
    end
  end

  test "performs a POST request and parses the output" do
    data = %{"some" => "stuff"}
    url = "http://nothing.com"
    token = "some_token"
    body = "{ \"groovy\": \"this is some json\"}"
    response = %HTTPoison.Response{body: body}
    with_mock HTTPoison, [ post: fn _url, _data, _headers -> {:ok, response} end ] do
      assert {:ok, %{"groovy" => "this is some json"}} == Gmail.HTTP.post(token, url, data)
    end
  end

end
