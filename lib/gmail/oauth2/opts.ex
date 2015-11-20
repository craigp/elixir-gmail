defmodule Gmail.OAuth2.Opts do

  use Timex

  defstruct user_id: "",
    client_id: "",
    client_secret: "",
    access_token: "",
    refresh_token: "",
    expires_at: "",
    token_type: "Bearer"

  @doc """
  Gets and build the config for the current environment
  """
  def from_config do
    Map.merge(%Gmail.OAuth2.Opts{}, Enum.into(Application.get_env(:gmail, :oauth2), %{}))
  end

end

