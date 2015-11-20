defmodule Gmail.Body do

  defstruct size: 0, data: ""

  @doc """
  Converts the mail body from Base64
  """
  def convert(%{"data" => data, "size" => size}) do
    %Gmail.Body{data: decode_body(data), size: size}
  end

  @doc """
  Used if there is no body data returned
  """
  def convert(%{"size" => size}) do
    %Gmail.Body{size: size}
  end

  def decode_body(data) do
    case Base.decode64(data) do
      {:ok, message} ->
        message
      :error ->
        data
    end
  end

end
