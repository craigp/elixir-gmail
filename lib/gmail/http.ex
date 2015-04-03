defmodule Gmail.HTTP do

  def get(token, url) do
    token = "ya29.SgFQypeLFpKaOoleDwESIALT-QlfufpPoYIHrHGSUtHprIpJPma8Kqq1"
    IO.puts "token: #{token}"
    IO.puts "url: #{url}"
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
    IO.inspect headers
    {:ok, response} = HTTPoison.get(url, headers)
    IO.inspect(response)
    parse_body(response)
  end

  def parse_body(%HTTPoison.Response{body: body}) do
    case Poison.Parser.parse(body) do
      {:ok, body} -> body
      {:error, _error} -> nil
    end
  end

end
