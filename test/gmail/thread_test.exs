ExUnit.start

defmodule Gmail.ThreadTest do

  use ExUnit.Case
  import Mock

  setup do
    expected_result = %Gmail.Thread{history_id: "2435435", id: "34534345",
      messages: [%Gmail.Message{history_id: "12123", id: "23443513177",
          label_ids: ["INBOX", "CATEGORY_PERSONAL"],
          payload: %Gmail.Payload{body: %Gmail.Body{data: "the actual body",
              size: 234}, filename: "", headers: ["header-1", "header-2"],
            mime_type: "text/html", part_id: "", parts: []}, raw: "",
          size_estimate: 23433, snippet: "This is a message snippet",
          thread_id: "234234234"}], snippet: ""}

    message = %{"id" => "23443513177",
      "threadId"     => "234234234",
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
      "id"         => "34534345",
      "historyId"  => "2435435",
      "messages"   => [message]
    }

    {:ok, thread: thread, message: message, expected_result: expected_result}
  end

  test "gets a thread when only provided an ID", context do
    with_mock Gmail.Base, [do_get: fn _path -> {:ok, context[:thread]} end ] do
      assert context[:expected_result] == Gmail.Thread.get("23434234234")
    end
  end

  test "gets a thread when provided with a user ID and ID", context do
    with_mock Gmail.Base, [do_get: fn _path -> {:ok, context[:thread]} end ] do
      assert context[:expected_result] == Gmail.Thread.get("user_id_233224", "23434234234")
    end
  end

  test "searches for a thread given a search query" do

  end

  test "gets a list of threads given a user ID" do

  end


end


