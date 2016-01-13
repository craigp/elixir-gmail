defmodule Gmail.Payload do

  @moduledoc """
  Helper functions for dealing with email payloads.
  """

  alias __MODULE__
  alias Gmail.Body

  defstruct part_id: "",
    mime_type: "",
    filename: "",
    headers: [],
    body: %Body{},
    parts: []

  @type t :: %__MODULE__{}

  @doc """
  Converts an email payload.
  """
  @spec convert(map) :: Payload.t
  def convert(%{"partId" => part_id,
    "mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body,
    "parts" => parts}) do
    %Payload{part_id: part_id,
      mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Body.convert(body),
      parts: Enum.map(parts, &convert/1)}
  end

  @doc """
  Converts an email payload.
  """
  def convert(%{"partId" => part_id,
    "mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body}) do
    %Payload{part_id: part_id,
      mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Body.convert(body)}
  end

  @doc """
  Converts an email payload.
  """
  def convert(%{"mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body,
    "parts" => parts}) do
    %Payload{mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Body.convert(body),
      parts: Enum.map(parts, &convert/1)}
  end

  @doc """
  Converts an email payload.
  """
  def convert(%{"mimeType" => mime_type,
    "filename" => filename,
    "headers" => headers,
    "body" => body}) do
    %Payload{mime_type: mime_type,
      filename: filename,
      headers: headers,
      body: Body.convert(body)}
  end

end
