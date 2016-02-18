ExUnit.start

defmodule Gmail.BaseTest do

  use ExUnit.Case
  import Mock

  setup do
    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}
    {:ok, %{
        bypass: bypass
      }}
  end

  test "gets the config from the OAuth2 client and makes a GET request", %{bypass: bypass} do
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/" <> some_url == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, "foo")
    end
    access_token_rec = %{access_token: access_token}
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      Gmail.Base.do_get(some_url)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets the config from the OAuth2 client and makes a POST request", %{bypass: bypass} do
    data = %{"some" => "stuff"}
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == data
      assert "/gmail/v1/" <> some_url == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, "foo")
    end
    access_token_rec = %{access_token: access_token}
      with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
        Gmail.Base.do_post(some_url, data)
        assert called Gmail.OAuth2.get_config
      end
  end

  test "gets the config from the OAuth2 client and makes a PUT request", %{bypass: bypass} do
    data = %{"some" => "stuff"}
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == data
      assert "/gmail/v1/" <> some_url == conn.request_path
      assert "" == conn.query_string
      assert "PUT" == conn.method
      Plug.Conn.resp(conn, 200, "foo")
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      Gmail.Base.do_put(some_url, data)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets the config from the OAuth2 client and makes a PATCH request", %{bypass: bypass} do
    data = %{"some" => "stuff"}
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == data
      assert "/gmail/v1/" <> some_url == conn.request_path
      assert "" == conn.query_string
      assert "PATCH" == conn.method
      Plug.Conn.resp(conn, 200, "foo")
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      Gmail.Base.do_patch(some_url, data)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets the config from the OAuth2 client and makes a DELETE request", %{bypass: bypass} do
    some_url = "foo/bar"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/" <> some_url == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 200, "foo")
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      Gmail.Base.do_delete(some_url)
      assert called Gmail.OAuth2.get_config
    end
  end

end
