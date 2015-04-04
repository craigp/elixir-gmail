defmodule Gmail.Payload do

  defstruct part_id: "",
    mime_type: "",
    filename: "",
    headers: [],
    body: %Gmail.Body{},
    parts: []

  # def convert(payload) do
  #   IO.inspect Dict.keys(payload)
  #   payload
  # end

  def convert(%{"partId" => part_id,
    "mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body,
    "parts" => parts}) do
    if length(parts) > 0 do
      IO.inspect Dict.keys(List.first(parts))
    end
    %Gmail.Payload{part_id: part_id,
      mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Gmail.Body.convert(body),
      parts: Enum.map(parts, &Gmail.Payload.convert/1)}
  end

  def convert(%{"mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body,
    "parts" => parts}) do
    if length(parts) > 0 do
      IO.inspect Dict.keys(List.first(parts))
    end
    %Gmail.Payload{mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Gmail.Body.convert(body),
      parts: Enum.map(parts, &Gmail.Payload.convert/1)}
  end

  def convert(%{"mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body}) do
    %Gmail.Payload{mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Gmail.Body.convert(body)}
  end


end
