defmodule Gmail.Body do

  defstruct size: 0, data: ""

  def convert(%{"data" => data, "size" => size}) do
    %Gmail.Body{data: decode_body(data), size: size}
  end

  def convert(%{"size" => size}) do
    %Gmail.Body{size: size}
  end

  defp decode_body(data) do
    case Base.decode64(data) do
      {:ok, message} ->
        message
      :error ->
        data
    end
  end

end
