ExUnit.start

defmodule Gmail.ThreadTest do

  use ExUnit.Case
  import Mock

  setup do
    thread_id = "34534345"
    history_id = "2435435"
    next_page_token = "23121233"

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
      bypass: bypass
    }
  end

  test "gets a thread", %{
    thread: thread,
    thread_id: thread_id,
    access_token_rec: access_token_rec,
    access_token: access_token,
    expected_result: expected_result,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/threads/#{thread_id}" == conn.request_path
      assert "format=full" == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, thread} = Gmail.Thread.get(thread_id)
      assert expected_result == thread
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a thread for a specified user", %{
    bypass: bypass,
    thread_id: thread_id,
    thread: thread,
    access_token_rec: access_token_rec,
    access_token: access_token,
    expected_result: expected_result
  } do
    email = "user@example.com"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email}/threads/#{thread_id}" == conn.request_path
      assert "format=full" == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(thread)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, thread} = Gmail.Thread.get(thread_id, email)
      assert expected_result == thread
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports :not_found for a thread that doesn't exist", %{
    thread_not_found: thread_not_found,
    access_token_rec: access_token_rec,
    thread_id: thread_id,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      {:ok, json} = Poison.encode(thread_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, :not_found} = Gmail.Thread.get(thread_id, "user@example.com")
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles a 400 error from the API", %{
    four_hundred_error: four_hundred_error,
    access_token_rec: access_token_rec,
    thread_id: thread_id,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, "Error #1"} = Gmail.Thread.get(thread_id, "user@example.com")
      assert called Gmail.OAuth2.get_config
    end
  end

  test "performs a thread search", %{
    bypass: bypass,
    search_results: search_results,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/threads" == conn.request_path
      assert "q=in:Inbox" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(search_results)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results} = Gmail.Thread.search("in:Inbox")
      assert expected_search_results === results
      assert called Gmail.OAuth2.get_config
    end
  end

  test "performs a thread search for a specified user", %{
    bypass: bypass,
    search_results: search_results,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
  } do
    email = "user@example.com"
    query = "in:Inbox"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email}/threads" == conn.request_path
      assert "q=#{query}" == conn.query_string
      {:ok, json} = Poison.encode(search_results)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results} = Gmail.Thread.search(query, email)
      assert expected_search_results === results
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a list of threads", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
    threads: threads,
    next_page_token: next_page_token
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/threads" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(threads)
      Plug.Conn.resp(conn, 200, json)
    end
      with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
        {:ok, results, page_token} = Gmail.Thread.list
        assert expected_search_results === results
        assert page_token == next_page_token
        assert called Gmail.OAuth2.get_config
      end
  end

  test "gets a list of threads with a user and no params", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
    threads: threads
  } do
    email = "user@example.com"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email}/threads" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(threads)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, results, next_page_token} = Gmail.Thread.list(email)
      assert expected_search_results === results
      assert next_page_token == next_page_token
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a list of threads with a user and page token", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
    threads: threads,
    next_page_token: next_page_token
  } do
    email = "user@example.com"
    requested_page_token = "435453455"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email}/threads" == conn.request_path
      assert "pageToken=#{requested_page_token}" == conn.query_string
      {:ok, json} = Poison.encode(threads)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      params = %{page_token: requested_page_token}
      {:ok, results, page_token} = Gmail.Thread.list(email, params)
      assert expected_search_results === results
      assert next_page_token == page_token
      assert called Gmail.OAuth2.get_config
    end
  end

  test "gets a list of threads with a user and params without page token", %{
    bypass: bypass,
    expected_search_results: expected_search_results,
    access_token_rec: access_token_rec,
    threads: threads
  } do
    email = "user@example.com"
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{email}/threads" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(threads)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      params = %{page_token_yarr: "345345345"}
      {:ok, results, _next_page_token} = Gmail.Thread.list(email, params)
      assert expected_search_results === results
      assert called Gmail.OAuth2.get_config
    end
  end

end


