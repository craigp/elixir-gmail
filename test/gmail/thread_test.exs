ExUnit.start

defmodule Gmail.ThreadTest do

  use ExUnit.Case
  import Mock

  setup do
    thread_id = "34534345"
    history_id = "2435435"
    next_page_token = "23121233"
    user_id = "user@example.com"

    expected_result = %Gmail.Thread{history_id: history_id, id: thread_id,
      messages: [%Gmail.Message{history_id: "12123", id: "23443513177",
          label_ids: ["INBOX", "CATEGORY_PERSONAL"],
          payload: %Gmail.Payload{body: %Gmail.Body{data: "the actual body",
              size: 234}, filename: "", headers: ["header-1", "header-2"],
            mime_type: "text/html", part_id: "", parts: []}, raw: "",
          size_estimate: 23433, snippet: "This is a message snippet",
          thread_id: thread_id}], snippet: ""}

    message = %{"id" => "23443513177",
      "threadId"     => thread_id,
      "labelIds"     => ["INBOX", "CATEGORY_PERSONAL"],
      "snippet"      => "This is a message snippet",
      "historyId"    => "12123",
      "payload"      => %{"mimeType" => "text/html",
        "filename" => "",
        "headers"  => ["header-1", "header-2"],
        "body"     => %{"data" => Base.encode64("the actual body"), "size" => 234},
        "parts"    => []},
      "sizeEstimate" => 23433
    }

    thread = %{
      "id"         => thread_id,
      "historyId"  => "2435435",
      "messages"   => [message],
      "snippet"    => "Thread #1"
    }

    other_thread = %{
      "id"         => "6576897",
      "historyId"  => "2435435",
      "messages"   => [],
      "snippet"    => "Thread #1"
    }

    threads = %{
      "threads" => [thread, other_thread],
      "nextPageToken" => next_page_token
    }

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    search_results = %{"threads" => [%{
          "id"         => thread_id,
          "historyId"  => "2435435",
          "snippet"    => "Thread #1"
        },
        %{
          "id"         => "6576897",
          "historyId"  => "2435435",
          "snippet"    => "Thread #1"
        }]
    }

    list_results = %{"threads" => [%{
          "id"         => thread_id,
          "historyId"  => "2435435",
          "snippet"    => "Thread #1"
        },
        %{
          "id"         => "6576897",
          "historyId"  => "2435435",
          "snippet"    => "Thread #1"
        }],
      "nextPageToken" => next_page_token
    }

    expected_search_results = [
      %Gmail.Thread{
        id: thread_id,
        history_id: "2435435",
        snippet: "Thread #1"
      },
      %Gmail.Thread{
        id: "6576897",
        history_id: "2435435",
        snippet: "Thread #1"
      }
    ]

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
      next_page_token: next_page_token,
      thread_id: thread_id,
      threads: threads,
      thread: thread,
      message: message,
      expected_result: expected_result,
      access_token: access_token,
      access_token_rec: access_token_rec,
      search_results: search_results,
      expected_search_results: expected_search_results,
      thread_not_found: %{"error" => %{"code" => 404}},
      four_hundred_error: %{"error" => %{"code" => 400, "errors" => errors}},
      bypass: bypass,
      list_results: list_results,
      user_id: user_id
    }
  end

  test "gets a thread", %{
    thread: thread,
    thread_id: thread_id,
    access_token: access_token,
    expected_result: expected_result,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads/#{thread_id}" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, thread} = Gmail.User.thread(user_id, thread_id)
    assert expected_result == thread
  end

  test "gets a thread, specifying the full format", %{
    thread: thread,
    thread_id: thread_id,
    access_token: access_token,
    expected_result: expected_result,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads/#{thread_id}" == conn.request_path
      assert "format=full" == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, thread} = Gmail.User.thread(user_id, thread_id, %{format: "full"})
    assert expected_result == thread
  end

  test "gets a thread, specifying the metadata format, with headers", %{
    thread: thread,
    thread_id: thread_id,
    access_token: access_token,
    expected_result: expected_result,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads/#{thread_id}" == conn.request_path
      assert URI.encode_query(%{"format" => "metadata", "metadataHeaders" => "header1,header1"}) == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, thread} = Gmail.User.thread(user_id, thread_id, %{format: "metadata", metadata_headers: ["header1", "header1"]})
    assert expected_result == thread
  end

  test "reports :not_found for a thread that doesn't exist", %{
    thread_not_found: thread_not_found,
    thread_id: thread_id,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      {:ok, json} = Poison.encode(thread_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.thread(user_id, thread_id)
  end

  test "handles a 400 error from the API", %{
    four_hundred_error: four_hundred_error,
    thread_id: thread_id,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, "Error #1"} = Gmail.User.thread(user_id, thread_id)
  end

  test "deletes a thread", %{
    thread_id: thread_id,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads/#{thread_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      Plug.Conn.resp(conn, 200, "")
    end
    assert :ok == Gmail.User.thread(:delete, user_id, thread_id)
  end

  test "trashes a thread", %{
    thread_id: thread_id,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id,
    thread: thread,
    expected_result: expected_result,
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads/#{thread_id}/trash" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "POST" == conn.method
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, result} = Gmail.User.thread(:trash, user_id, thread_id)
    assert result == expected_result
  end

  test "performs a thread search", %{
    bypass: bypass,
    search_results: search_results,
    expected_search_results: expected_search_results,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads" == conn.request_path
      assert URI.encode_query(%{"q" => "in:Inbox"}) == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(search_results)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, results} = Gmail.User.search(user_id, :thread, "in:Inbox")
    assert expected_search_results === results
  end

  test "gets a list of threads", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    list_results: list_results,
    next_page_token: next_page_token,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(list_results)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, results, page_token} = Gmail.User.threads(user_id)
    assert expected_search_results == results
    assert page_token == next_page_token
  end

  test "gets a list of threads with a page token", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    list_results: list_results,
    next_page_token: next_page_token,
    user_id: user_id
  } do
    requested_page_token = "435453455"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads" == conn.request_path
      assert "pageToken=#{requested_page_token}" == conn.query_string
      {:ok, json} = Poison.encode(list_results)
      Plug.Conn.resp(conn, 200, json)
    end
    params = %{page_token: requested_page_token}
    {:ok, results, page_token} = Gmail.User.threads(user_id, params)
    assert expected_search_results === results
    assert next_page_token == page_token
  end

  test "properly sends the maxResults query parameter", %{
    bypass: bypass,
    list_results: list_results,
    user_id: user_id
  } do
    max_results = 20
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads" == conn.request_path
      assert "maxResults=#{max_results}" == conn.query_string
      {:ok, json} = Poison.encode(list_results)
      Plug.Conn.resp(conn, 200, json)
    end
    params = %{max_results: max_results}
    {:ok, _results, _page_token} = Gmail.User.threads(user_id, params)
  end

  test "gets a list of threads with a user and params without page token (ignoring invalid param)", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    list_results: list_results,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/threads" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(list_results)
      Plug.Conn.resp(conn, 200, json)
    end
    params = %{page_token_yarr: "345345345"}
    {:ok, results, _page_token} = Gmail.User.threads(user_id, params)
    assert expected_search_results === results
  end

end


