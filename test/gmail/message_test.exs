ExUnit.start

defmodule Gmail.MessageTest do

  use ExUnit.Case
  import Mock

  setup do
    message_id = "23443513177"
    thread_id = "234234234"
    message = %{"id" => message_id,
      "threadId" => thread_id,
      "labelIds" => ["INBOX", "CATEGORY_PERSONAL"],
      "snippet" => "This is a message snippet",
      "historyId" => "12123",
      "payload" => %{"mimeType" => "text/html",
        "filename" => "",
        "headers" => ["header-1", "header-2"],
        "body" => %{"data" => Base.encode64("the actual body"), "size" => 234},
        "parts" => []},
      "sizeEstimate" => 23433
    }

    search_result = %{"messages" => [message]}

    expected_search_result = [%Gmail.Message{id: message_id, thread_id: thread_id}]

    expected_result = %Gmail.Message{history_id: "12123", id: message_id,
      label_ids: ["INBOX", "CATEGORY_PERSONAL"],
      payload: %Gmail.Payload{body: %Gmail.Body{data: "the actual body",
          size: 234}, filename: "", headers: ["header-1", "header-2"],
        mime_type: "text/html", part_id: "", parts: []}, raw: "",
      size_estimate: 23433, snippet: "This is a message snippet",
      thread_id: thread_id}

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    errors = [
      %{"message" => "Error #1"},
      %{"message" => "Error #2"}
    ]

    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}

    {:ok,
      message_id: message_id,
      message: message,
      access_token: access_token,
      access_token_rec: access_token_rec,
      expected_result: expected_result,
      search_result: search_result,
      expected_search_result: expected_search_result,
      message_not_found: %{"error" => %{"code" => 404}},
      four_hundred_error: %{"error" => %{"code" => 400, "errors" => errors}},
      bypass: bypass
    }
  end

  test "gets a message", %{
    message: message,
    access_token_rec: access_token_rec,
    message_id: message_id,
    expected_result: expected_result,
    bypass: bypass,
    access_token: access_token
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/messages/#{message_id}" == conn.request_path
      assert "format=full" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, message} = Gmail.Message.get(message_id)
      assert message == expected_result
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a message (body not base64 encoded, just for test coverage)", %{
    message: message,
    access_token_rec: access_token_rec,
    message_id: message_id,
    bypass: bypass
  } do
    body = %{message["payload"]["body"] | "data" => "not a base64 string"}
    payload = %{message["payload"] | "body" => body}
    message = %{message | "payload" => payload}
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/messages/#{message_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, _message} = Gmail.Message.get(message_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a message for a specified user", %{
    message: message,
    access_token_rec: access_token_rec,
    message_id: message_id,
    expected_result: expected_result,
    bypass: bypass
  } do
    email = "user@example.com"
    email_encoded = "user%40example.com" # for some reason URI.encode/1 doesn't encode the @
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email_encoded}/messages/#{message_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, message} = Gmail.Message.get(message_id, email)
      assert message == expected_result
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports :not_found for a message that doesn't exist", %{
    access_token_rec: access_token_rec,
    message_id: message_id,
    bypass: bypass,
    message_not_found: message_not_found
  } do
    email = "user@example.com"
    email_encoded = "user%40example.com" # for some reason URI.encode/1 doesn't encode the @
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email_encoded}/messages/#{message_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(message_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, :not_found} = Gmail.Message.get(message_id, email)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles a 400 error from the API", %{
    access_token_rec: access_token_rec,
    message_id: message_id,
    bypass: bypass,
    four_hundred_error: four_hundred_error
  } do
    email = "user@example.com"
    email_encoded = "user%40example.com" # for some reason URI.encode/1 doesn't encode the @
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email_encoded}/messages/#{message_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, "Error #1"} = Gmail.Message.get(message_id, email)
      assert called Gmail.OAuth2.get_config
      # assert called Gmail.HTTP.get(access_token, Gmail.Base.base_url <> "users/user@example.com/messages/" <> message_id <> "?format=full")
    end
  end

  test "performs a message search", %{
    access_token_rec: access_token_rec,
    bypass: bypass,
    search_result: search_result,
    expected_search_result: expected_search_result
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/messages" == conn.request_path
      assert "q=in:Inbox" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(search_result)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results} = Gmail.Message.search("in:Inbox")
      assert results == expected_search_result
      assert called Gmail.OAuth2.get_config
    end
  end

  test "performs a message search for a specified user", %{
    message: message,
    access_token_rec: access_token_rec,
    expected_search_result: expected_search_result,
    bypass: bypass
  } do
    email = "user@example.com"
    email_encoded = "user%40example.com" # for some reason URI.encode/1 doesn't encode the @
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email_encoded}/messages" == conn.request_path
      assert "q=in:Inbox" == conn.query_string
      {:ok, json} = Poison.encode(%{"messages" => [message]})
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results} = Gmail.Message.search("in:Inbox", email)
      assert results == expected_search_result
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a list of messages", %{
    message: message,
    access_token_rec: access_token_rec,
    bypass: bypass,
    expected_search_result: expected_search_result
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/messages" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(%{"messages" => [message]})
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results} = Gmail.Message.list
      assert results == expected_search_result
      assert called Gmail.OAuth2.get_config
    end
  end

end

