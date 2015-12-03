defmodule Gmail.Body do

  defstruct size: 0, data: ""
  @type t :: %__MODULE__{}

  @doc """
  Converts the mail body from Base64
  """
  @spec convert(Map.t) :: Gmail.Body.t
  def convert(%{"data" => data, "size" => size}) do
    %Gmail.Body{data: decode_body(data), size: size}
  end

  @doc """
  Converts mail body if there is no body data returned
  """
  @spec convert(Map.t) :: Gmail.Body.t
  def convert(%{"size" => size}) do
    %Gmail.Body{size: size}
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
