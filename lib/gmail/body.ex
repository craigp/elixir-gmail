defmodule Gmail.Body do

  @moduledoc """
  Helper functions for dealing with email bodies.
  """

  defstruct size: 0, data: ""
  @type t :: %__MODULE__{}

  @doc """
  Converts the email body, attempting to decode from Base64 if there is body data.
  """
  @spec convert(Map.t) :: Gmail.Body.t
  def convert(body) do
    case body do
      %{"data" => data, "size" => size} ->
        %Gmail.Body{data: decode_body(data), size: size}
      %{"size" => size} ->
        %Gmail.Body{size: size}
    end
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
