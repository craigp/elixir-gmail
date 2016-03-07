defmodule Gmail.OAuth2 do

  @moduledoc """
  OAuth2 access token handling.
  """

  use GenServer
  alias __MODULE__
  import Poison, only: [decode: 1]
  use Timex
  require Logger

  defstruct user_id: nil,
    client_id: nil,
    client_secret: nil,
    access_token: nil,
    refresh_token: nil,
    expires_at: 0,
    token_type: "Bearer"
  @type t :: %__MODULE__{}

  #  Server API {{{ #

  @doc false
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(:ok) do
    %OAuth2{refresh_token: refresh_token} = config = from_config_file
    if refresh_token do
      IO.puts "refreshing access token"
      if access_token_expired?(config) do
        {:ok, config} = refresh_access_token(config)
      end
    else
      IO.puts "FML"
      Logger.warn "No refresh token found in config, cannot refresh access token"
    end
    {:ok, %{config: config}}
  end

  def handle_call(:config, _from, %{config: config} = state) do
    if access_token_expired?(config) do
      IO.puts "refreshing acces token"
      {:ok, config} = refresh_access_token(config)
      state = %{state | config: config}
    end
    {:reply, config, state}
  end

  #  }}} Server API #

  # @auth_url "https://accounts.google.com/o/oauth2/auth"
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
  @spec access_token_expired?(OAuth2.t) :: boolean
  def access_token_expired?(%OAuth2{expires_at: expires_at}) do
    Date.to_secs(Date.now) >= expires_at
  end

  @doc """
  Gets the config for a Gmail API connection, including a refreshed access token.
  """
  @spec get_config() :: OAuth2.t
  def get_config do
    GenServer.call(__MODULE__, :config)
  end

  @doc """
  Refreshes an expired access token.
  """
  @spec refresh_access_token(OAuth2.t) :: {atom, OAuth2.t}
  def refresh_access_token(%OAuth2{client_id: client_id, client_secret: client_secret, refresh_token: refresh_token} = opts) do
    payload = %{
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    } |> URI.encode_query
    case HTTPoison.post(@token_url, payload, @token_headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        case decode(body) do
          {:ok, %{"access_token" => access_token, "expires_in" => expires_in}} ->
            {:ok, %{opts | access_token: access_token, expires_at: (Date.to_secs(Date.now) + expires_in)}}
          fml -> {:error, fml}
        end
      not_ok -> {:error, not_ok}
    end
  end

  @spec from_config_file() :: OAuth2.t
  defp from_config_file do
    case Application.get_env(:gmail, :oauth2) do
      nil ->
        %OAuth2{}
      config ->
        struct(OAuth2, config)
    end
  end

end
