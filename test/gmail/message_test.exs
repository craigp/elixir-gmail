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
    user_id = "user@example.com"

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

    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {access_token, 100000000000000} end] do
      {:ok, _server_pid} = Gmail.User.start_mail(user_id, "dummy-refresh-token")
    end

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
      bypass: bypass,
      user_id: user_id
    }
  end

  test "gets a message", %{
    message: message,
    message_id: message_id,
    expected_result: expected_result,
    bypass: bypass,
    access_token: access_token,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, message} = Gmail.User.message(user_id, message_id)
    assert message == expected_result
  end

  test "gets a message (body not base64 encoded, just for test coverage)", %{
    message: message,
    message_id: message_id,
    bypass: bypass,
    user_id: user_id
  } do
    body = %{message["payload"]["body"] | "data" => "not a base64 string"}
    payload = %{message["payload"] | "body" => body}
    message = %{message | "payload" => payload}
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, _message} = Gmail.User.message(user_id, message_id)
  end

  test "reports :not_found for a message that doesn't exist", %{
    message_id: message_id,
    bypass: bypass,
    message_not_found: message_not_found,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(message_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.message(user_id, message_id)
  end

  test "deletes a message", %{
    message_id: message_id,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 200, "")
    end
    assert :ok == Gmail.User.message(:delete, user_id, message_id)
  end

  test "trashes a message", %{
    message_id: message_id,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id,
    message: message,
    expected_result: expected_result
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}/trash" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "POST" == conn.method
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, result} = Gmail.User.message(:trash, user_id, message_id)
    assert result == expected_result
  end

  test "untrashes a message", %{
    message_id: message_id,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id,
    message: message,
    expected_result: expected_result
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}/untrash" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "POST" == conn.method
      {:ok, json} = Poison.encode(message)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, result} = Gmail.User.message(:untrash, user_id, message_id)
    assert result == expected_result
  end

  test "handles a 400 error from the API", %{
    message_id: message_id,
    bypass: bypass,
    four_hundred_error: four_hundred_error,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages/#{message_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, "Error #1"} = Gmail.User.message(user_id, message_id)
  end

  test "performs a message search", %{
    bypass: bypass,
    search_result: search_result,
    expected_search_result: expected_search_result,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages" == conn.request_path
      assert URI.encode_query(%{"q" => "in:Inbox"}) == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(search_result)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, results} = Gmail.User.search(user_id, :message, "in:Inbox")
    assert results == expected_search_result
  end

  test "gets a list of messages", %{
    message: message,
    bypass: bypass,
    expected_search_result: expected_search_result,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/messages" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(%{"messages" => [message]})
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, results} = Gmail.User.messages(user_id)
    assert results == expected_search_result
  end

end

