ExUnit.start

defmodule Gmail.ThreadTest do

  use ExUnit.Case
  import Mock

  setup do
    thread_id = "34534345"

    expected_result = %Gmail.Thread{history_id: "2435435", id: thread_id,
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
        "body"     => %{"data" => "the actual body", "size" => 234},
        "parts"    => []},
      "sizeEstimate" => 23433
    }

    thread = %{
      "id"         => thread_id,
      "historyId"  => "2435435",
      "messages"   => [message]
    }

    other_thread = %{
      "id"         => "6576897",
      "historyId"  => "2435435",
      "messages"   => []
    }

    threads = %{
      "threads" => [thread, other_thread],
      "next_page_token" => "23434345"
    }

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    {:ok,
      thread_id: thread_id,
      threads: threads,
      thread: thread,
      message: message,
      expected_result: expected_result,
      access_token: access_token,
      access_token_rec: access_token_rec
    }
  end

  test "gets a thread", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:thread] } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> context[:access_token_rec] end ] do
        thread = Gmail.Thread.get(context[:thread_id])
        assert context[:expected_result] == thread
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads/" <> context[:thread_id])
      end
    end
  end

  test "gets a thread for a specified user", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:thread] } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> context[:access_token_rec] end ] do
        thread = Gmail.Thread.get("user@example.com", context[:thread_id])
        assert context[:expected_result] == thread
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads/" <> context[:thread_id])
      end
    end
  end

  test "performs a thread search", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:thread] } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> context[:access_token_rec] end ] do
        results = Gmail.Thread.search("in:Inbox")
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads?q=in:Inbox")
      end
    end
  end

  test "performs a thread search for a specified user", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:thread] } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> context[:access_token_rec] end ] do
        results = Gmail.Thread.search("user@example.com", "in:Inbox")
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/user@example.com/threads?q=in:Inbox")
      end
    end
  end

  test "gets a list of threads", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:thread] } end] do
      with_mock Gmail.OAuth2.Client, [ get_config: fn -> context[:access_token_rec] end ] do
        results = Gmail.Thread.list
        # TODO need to test results
        assert called Gmail.OAuth2.Client.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/threads")
      end
    end
  end


end


