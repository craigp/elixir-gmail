defmodule Gmail.XOAuth2.Opts do

  use Timex

  defstruct user_id: "",
    client_id: "",
    client_secret: "",
    access_token: "",
    refresh_token: "",
    expires_at: "",
    token_type: "Bearer"

  def from_config do
    Map.merge(%Gmail.XOAuth2.Opts{}, Enum.into(Application.get_env(:gmail, :xoauth2), %{}))
  end

end

