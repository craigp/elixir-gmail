defmodule Gmail.OAuth2 do

  @moduledoc """
  OAuth2 access token handling.
  """

  use GenServer
  import Poison, only: [decode: 1]
  use Timex

  #  Server API {{{ #

  @doc false
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc false
  def init(:ok) do
    {:ok, %{config: from_config_file}}
  end

  @doc false
  def handle_call(:config, _from, %{config: config} = state) do
    {:reply, config, state}
  end

  @doc false
  def handle_call({:refresh_access_token, refresh_token}, _from, %{config: config} = state) do
    {:ok, access_token, expires_at} = do_refresh_access_token(config, refresh_token)
    {:reply, {access_token, expires_at}, state}
  end

  #  }}} Server API #

  @token_url "https://accounts.google.com/o/oauth2/token"
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}
  @scope "https://mail.google.com/"

  #  Client API {{{ #

  @doc ~S"""
  Checks if an access token has expired.

  ### Examples

      iex> Gmail.OAuth2.access_token_expired?(%{expires_at: 1})
      true

      iex> Gmail.OAuth2.access_token_expired?(%{expires_at: (Timex.Date.to_secs(Timex.Date.now) + 10)})
      false

  """
  @spec access_token_expired?(map) :: boolean
  def access_token_expired?(%{expires_at: expires_at}) do
    Date.to_secs(Date.now) >= expires_at
  end

  @spec refresh_access_token(String.t) :: {String.t, number}
  def refresh_access_token(refresh_token) do
    GenServer.call(__MODULE__, {:refresh_access_token, refresh_token})
  end

  @doc """
  Gets the config for a Gmail API connection, including a refreshed access token.
  """
  @spec get_config() :: map
  def get_config do
    GenServer.call(__MODULE__, :config)
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec do_refresh_access_token(map, String.t) :: {atom, map}
  defp do_refresh_access_token(%{client_id: client_id, client_secret: client_secret}, refresh_token) do
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
            {:ok, access_token, (Date.to_secs(Date.now) + expires_in)}
          fml ->
            {:error, fml}
        end
      not_ok ->
        {:error, not_ok}
    end
  end

  @spec from_config_file() :: map
  defp from_config_file do
    case Application.get_env(:gmail, :oauth2) do
      nil ->
        %{}
      config ->
        Enum.into(config, Map.new)
    end
  end

  #  }}} Private functions #

end
