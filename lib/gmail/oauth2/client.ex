defmodule Gmail.OAuth2.Client do

  use Timex

  @auth_url "https://accounts.google.com/o/oauth2/auth"
  @token_url "https://accounts.google.com/o/oauth2/token"
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @scope "https://mail.google.com/"

  # TODO this won't really work, and needs to be in some sort of config - the redirect_uri needs to match
  # one this is pre-configured in the google developers panel thingy
  @redirect_uri "http://widdershins.co.za"

  # @doc ~S"""
  # Creates an authorisation URL given the OAuth client ID

  # ## Examples

  #     iex> Gmail.OAuth2.Client.authorisation_url(%Gmail.OAuth2.Opts{client_id: "12345"})
  #     {:ok, "https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=12345&redirect_uri=http%3A%2F%2Fwiddershins.co.za&response_type=code&scope=https%3A%2F%2Fmail.google.com%2F"}

  # """
  # def authorisation_url(%Gmail.OAuth2.Opts{client_id: client_id}) do
  #   query = %{
  #     response_type: "code",
  #     client_id: client_id,
  #     scope: @scope,
  #     access_type: "offline",
  #     redirect_uri: @redirect_uri
  #   } |> URI.encode_query
  #   {:ok, "#{@auth_url}?#{query}"}
  # end

  @doc """
  Checks if an access token has expired

  ### Examples

      iex> Gmail.OAuth2.Client.access_token_expired?(%Gmail.OAuth2.Opts{expires_at: 1})
      true

      iex> Gmail.OAuth2.Client.access_token_expired?(%Gmail.OAuth2.Opts{expires_at: (Timex.Date.to_secs(Timex.Date.now) + 10)})
      false

  """
  def access_token_expired?(%Gmail.OAuth2.Opts{expires_at: expires_at}) do
    Date.to_secs(Date.now) >= expires_at
  end

  @doc ~S"""
  Gets the config for a Gmail API connection, including a refreshed access token
  """
  def get_config do
    config = Gmail.OAuth2.Opts.from_config
    if access_token_expired?(config) do
      {:ok, config} = refresh_access_token(config)
    end
    config
  end

  @doc ~S"""
  Refreshes an expired access token
  """
  def refresh_access_token(opts) do
    %Gmail.OAuth2.Opts{client_id: client_id, client_secret: client_secret, refresh_token: refresh_token} = opts
    payload = %{
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    } |> URI.encode_query
    case HTTPoison.post(@token_url, payload, @token_headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case Poison.Parser.parse(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{opts | access_token: access_token, expires_at: (Date.to_secs(Date.now) + expires_in)}}
          fml -> {:error, fml}
        end
      not_ok -> {:error, not_ok}
    end
  end

  # def generate_token(opts \\ %Gmail.OAuth2.Opts{}) do
  #   payload = opts
  #     |> url_options
  #     |> URI.encode_query
  #   case HTTPoison.post(opts.url, payload, @token_headers) do
  #     {:ok, response} ->
  #       response
  #         |> parse_response_body
  #         |> build_token(opts.user_id)
  #     _ -> nil
  #   end
  # end

  # def url_options(opts) do
  #   url_opts = %{
  #     grant_type: "refresh_token",
  #     client_id: opts.client_id,
  #     client_secret: opts.client_secret,
  #     refresh_token: opts.refresh_token
  #   }
  #   url_opts
  # end

  # def parse_response_body(%HTTPoison.Response{body: body}) do
  #   case Poison.Parser.parse(body) do
  #     {:ok, parsed} -> parsed
  #     # {:ok, %{"access_token" => token}} -> token
  #     # {:ok, _body} -> nil
  #     {:error, _error} -> nil
  #   end
  # end

  # def build_token(access_token, user_id) do
  #   IO.puts "access_token: " <> access_token
  #   ["user=" <> user_id, "auth=Bearer " <> access_token, "", ""]
  #     |> Enum.join("\x{01}")
  #     |> Base.encode64
  # end

end
