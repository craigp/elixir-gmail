defmodule Gmail.OAuth2 do

  @moduledoc """
  OAuth2 access token handling.
  """

  alias Gmail.Utils
  import Poison, only: [decode: 1]

  @typep refresh_access_token_response :: {:error, any} | {:ok, String.t, number}

  @token_url "https://accounts.google.com/o/oauth2/token"
  @token_headers %{"Content-Type" => "application/x-www-form-urlencoded"}

  #  Client API {{{ #

  @doc ~S"""
  Checks if an access token has expired.

  ### Examples

      iex> Gmail.OAuth2.access_token_expired?(%{expires_at: 1})
      true

      iex> Gmail.OAuth2.access_token_expired?(%{expires_at: (DateTime.to_unix(DateTime.utc_now) + 10)})
      false

  """
  @spec access_token_expired?(map) :: boolean
  def access_token_expired?(%{expires_at: expires_at}) do
    :os.system_time(:seconds) >= expires_at
  end

  @spec refresh_access_token(String.t) :: {:ok, {String.t, integer}} | {:error, any}
  def refresh_access_token(refresh_token) when is_binary(refresh_token) do
    case do_refresh_access_token(refresh_token) do
      {:ok, access_token, expires_at} ->
        {:ok, {access_token, expires_at}}
      {:error, _} = err ->
        err
    end
  end

  #  }}} Client API #

  #  Private functions {{{ #

  @spec do_refresh_access_token(String.t | map) :: refresh_access_token_response
  defp do_refresh_access_token(refresh_token) when is_binary(refresh_token) do
    :oauth2
    |> Utils.load_config
    |> Enum.into(%{})
    |> do_refresh_access_token(refresh_token)
  end

  defp do_refresh_access_token(%{client_id: client_id, client_secret: client_secret}, refresh_token) when is_binary(refresh_token) do
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
            {:ok, access_token, (:os.system_time(:seconds) + expires_in)}
          {:error, _} = err ->
            err
        end
      {:error, _} = err ->
        err
    end
  end

  #  }}} Private functions #

end
