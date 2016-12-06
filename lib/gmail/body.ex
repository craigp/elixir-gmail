defmodule Gmail.Body do

  @moduledoc """
  Helper functions for dealing with email bodies.
  """

  alias __MODULE__
  alias Gmail.Utils

  defstruct size: 0, data: "", attachment_id: ""
  @type t :: %__MODULE__{}

  @doc """
  Converts the email body, attempting to decode from Base64 if there is body data.
  """
  @spec convert(Map.t) :: Body.t
  def convert(body) do
    {data, body} = body |> Utils.atomise_keys |> Map.pop(:data)
    body = if data, do: Map.put(body, :data, decode_body(data)), else: body
    struct(Body, body)
  end

  @spec decode_body(String.t) :: String.t
  defp decode_body(data) do
    case Base.decode64(data) do
      {:ok, message} ->
        message
      :error ->
        data
    end
  end

end
