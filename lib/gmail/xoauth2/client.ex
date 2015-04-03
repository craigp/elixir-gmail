defmodule Gmail.XOAuth2.Client do

  use Timex

  def token_headers do
    %{"Content-Type" => "application/x-www-form-urlencoded"}
  end

  def access_token_expired?(%Gmail.XOAuth2.Opts{expires_at: expires_at}) do
    Date.convert(Date.now, :secs) >= expires_at
  end

  def refresh_access_token(opts) do
    %Gmail.XOAuth2.Opts{url: url, client_id: client_id, client_secret: client_secret, refresh_token: refresh_token} = opts
    payload = %{
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    } |> URI.encode_query
    case HTTPoison.post(url, payload, token_headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.Parser.parse(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            %{opts | access_token: access_token, expires_at: (Date.convert(Date.now, :secs) + expires_in)}
          fml -> {:error, fml}
        end
      _ -> nil
    end
  end

  def generate_token(opts \\ %Gmail.XOAuth2.Opts{}) do
    payload = opts
      |> url_options
      |> URI.encode_query
    case HTTPoison.post(opts.url, payload, token_headers) do
      {:ok, response} ->
        response
          |> parse_response_body
          |> build_token(opts.user_id)
      _ -> nil
    end
  end

  def url_options(opts) do
    url_opts = %{
      grant_type: "refresh_token",
      client_id: opts.client_id,
      client_secret: opts.client_secret,
      refresh_token: opts.refresh_token
    }
    url_opts
  end

  def parse_response_body(%HTTPoison.Response{body: body}) do
    case Poison.Parser.parse(body) do
      {:ok, parsed} -> parsed
      # {:ok, %{"access_token" => token}} -> token
      # {:ok, _body} -> nil
      {:error, _error} -> nil
    end
  end

  def build_token(access_token, user_id) do
    IO.puts "access_token: " <> access_token
    ["user=" <> user_id, "auth=Bearer " <> access_token, "", ""]
      |> Enum.join("\x{01}")
      |> Base.encode64
  end

end
