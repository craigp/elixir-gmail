defmodule Gmail.OAuth2 do

  @moduledoc """
  OAuth2 access token handling.
  """

  use Timex

  defstruct user_id: "",
    client_id: "",
    client_secret: "",
    access_token: "",
    refresh_token: "",
    expires_at: "",
    token_type: "Bearer"

  @type t :: %__MODULE__{}

  @auth_url "https://accounts.google.com/o/oauth2/auth"
  @token_url "https://accounts.google.com/o/oauth2/token"
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @scope "https://mail.google.com/"

  @doc ~S"""
  Checks if an access token has expired.

  ### Examples

      iex> Gmail.OAuth2.access_token_expired?(%Gmail.OAuth2{expires_at: 1})
      true

      iex> Gmail.OAuth2.access_token_expired?(%Gmail.OAuth2{expires_at: (Timex.Date.to_secs(Timex.Date.now) + 10)})
      false

  """
  @spec access_token_expired?(Gmail.OAuth2.t) :: boolean
  def access_token_expired?(%Gmail.OAuth2{expires_at: expires_at}) do
    Date.to_secs(Date.now) >= expires_at
  end

  @doc """
  Gets the config for a Gmail API connection, including a refreshed access token.
  """
  @spec get_config() :: Gmail.OAuth2.t
  def get_config do
    config = from_config
    if access_token_expired?(config) do
      {:ok, config} = refresh_access_token(config)
    end
    config
  end

  @doc """
  Refreshes an expired access token.
  """
  @spec refresh_access_token(Gmail.OAuth2.t) :: {atom, Gmail.OAuth2.t}
  def refresh_access_token(opts) do
    %Gmail.OAuth2{client_id: client_id, client_secret: client_secret, refresh_token: refresh_token} = opts
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

  @spec from_config() :: Gmail.OAuth2.t
  defp from_config do
    Map.merge(%Gmail.OAuth2{}, Enum.into(Application.get_env(:gmail, :oauth2), %{}))
  end

end
