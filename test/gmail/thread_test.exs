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

    search_results = {:ok, %{"threads" => [%{
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
      four_hundred_error: %{"error" => %{"code" => 400, "errors" => errors}}
    }
  end

  test "gets a thread", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:thread]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, thread} = Gmail.Thread.get(context[:thread_id])
        assert context[:expected_result] == thread
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads/" <> context[:thread_id])
      end
    end
  end

  test "gets a thread for a specified user", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:thread]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, thread} = Gmail.Thread.get(context[:thread_id], "user@example.com")
        assert context[:expected_result] == thread
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads/" <> context[:thread_id])
      end
    end
  end

  test "reports :not_found for a thread that doesn't exist", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:thread_not_found]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:error, :not_found} = Gmail.Thread.get(context[:thread_id], "user@example.com")
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads/" <> context[:thread_id])
      end
    end
  end

  test "handles a 400 error from the API", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:four_hundred_error]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:error, "Error #1"} = Gmail.Thread.get(context[:thread_id], "user@example.com")
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads/" <> context[:thread_id])
      end
    end
  end

  test "performs a thread search", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> context[:search_results] end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, results} = Gmail.Thread.search("in:Inbox")
        assert context[:expected_search_results] === results
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads?q=in:Inbox")
      end
    end
  end

  test "performs a thread search for a specified user", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> context[:search_results] end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, results} = Gmail.Thread.search("in:Inbox", "user@example.com")
        assert context[:expected_search_results] === results
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads?q=in:Inbox")
      end
    end
  end

  test "gets a list of threads", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:threads]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, results, next_page_token} = Gmail.Thread.list
        assert context[:expected_search_results] === results
        assert context[:next_page_token] == next_page_token
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads")
      end
    end
  end

  test "gets a list of threads with a user and no params", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:threads]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, results, next_page_token} = Gmail.Thread.list("user@example.com")
        assert context[:expected_search_results] === results
        assert context[:next_page_token] == next_page_token
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/user@example.com/threads")
      end
    end
  end

  test "gets a list of threads with a user and page token", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:threads]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        params = %{page_token: "345345345"}
        {:ok, results, next_page_token} = Gmail.Thread.list("user@example.com", params)
        assert context[:expected_search_results] === results
        assert context[:next_page_token] == next_page_token
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/user@example.com/threads?pageToken=" <> params[:page_token])
      end
    end
  end

  test "gets a list of threads with a user and params without page token", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:threads]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        params = %{page_token_yarr: "345345345"}
        {:ok, results, _next_page_token} = Gmail.Thread.list("user@example.com", params)
        assert context[:expected_search_results] === results
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/user@example.com/threads")
      end
    end
  end

  # this requires gmail config to be setup in config/test.local.exs
  if File.exists?("./config/test.local.exs") do
    test "getting threads without all the mocking" do
      {:ok, [first_thread|_other_threads], _next_page_token} = Gmail.Thread.list
      {:ok, thread} = Gmail.Thread.get(first_thread.id)
      assert thread.id === first_thread.id
      assert thread.history_id === first_thread.history_id
    end
  end
end


