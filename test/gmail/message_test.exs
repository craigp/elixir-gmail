ExUnit.start

defmodule Gmail.MessageTest do

  use ExUnit.Case
  import Mock

  test "gets a message when only provided an ID" do
    message = %{"id" => "23443513177",
      "threadId" => "234234234",
      "labelIds" => ["INBOX", "CATEGORY_PERSONAL"],
      "snippet" => "This is a message snippet",
      "historyId" => "12123",
      "payload" => %{"mimeType" => "text/html",
        "filename" => "",
        "headers" => ["header-1", "header-2"],
        "body" => %{"data" => "the actual body", "size" => 234},
        "parts" => []},
      "sizeEstimate" => 23433
    }
    with_mock Gmail.Base, [ do_get: fn _path -> {:ok, message} end ] do
      Gmail.Message.get("14f02d60a9d28633")
    end
  end

  test "searches for a message given a search query" do

  end

  test "gets a list of messages given a user ID" do

  end


end

