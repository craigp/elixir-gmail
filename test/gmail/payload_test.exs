ExUnit.start

defmodule Gmail.PayloadTest do

  use ExUnit.Case

  test "converts a payload with a part ID and parts" do
    mimeType = "mimeType"
    filename = "some_file_name"
    headers = ["header_1", "header_2"]
    body = %{"data" => "body_data", "size" => 12}
    parts = [%{
        "partId" => "1",
        "filename" => filename,
        "mimeType" => mimeType,
        "headers" => headers,
        "body" => body,
        "parts" => []
      }, %{
        "partId" => "2",
        "filename" => filename,
        "mimeType" => mimeType,
        "headers" => headers,
        "body" => body
      }]
    payload = %{"mimeType" => mimeType,
      "filename" => filename,
      "headers" => headers,
      "body" => body,
      "parts" => parts}
    Gmail.Payload.convert(payload)
  end

  test "converts a payload with parts but no part ID" do
    mimeType = "mimeType"
    filename = "some_file_name"
    headers = ["header_1", "header_2"]
    body = %{"data" => "body_data", "size" => 12}
    parts = [%{
        "partId" => "1",
        "filename" => filename,
        "mimeType" => mimeType,
        "headers" => headers,
        "body" => body
      }, %{
        "partId" => "2",
        "filename" => filename,
        "mimeType" => mimeType,
        "headers" => headers,
        "body" => body
      }]
    payload = %{"mimeType" => mimeType,
      "filename" => filename,
      "headers" => headers,
      "body" => body,
      "parts" => parts}
    Gmail.Payload.convert(payload)
  end

  test "converts a payload with no parts or part ID" do
    filename = "some_file_name"
    headers = ["header_1", "header_2"]
    body = %{"data" => "body_data", "size" => 12}
    mimeType = "mimeType"
    payload = %{"mimeType" => mimeType,
      "filename" => filename,
      "headers" => headers,
      "body" => body}
    Gmail.Payload.convert(payload)
  end

end
