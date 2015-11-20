defmodule Gmail.HTTP do

  @doc """
  Performs a GET request against the Gmail API
  """
  def get(token, url) do
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
    {:ok, response} = HTTPoison.get(url, headers)
    {:ok, parse_body(response)}
  end

  defp parse_body(%HTTPoison.Response{body: body}) do
    case Poison.Parser.parse(body) do
      {:ok, body} -> body
      {:error, _error} -> nil
    end
  end

end
