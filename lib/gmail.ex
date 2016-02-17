defmodule Gmail do

  @moduledoc """
  A simple Gmail REST API client for Elixir, mostly built as a learning exercise.

  You can find the hex package [here](https://hex.pm/packages/gmail), and the docs [here](http://hexdocs.pm/gmail).

  You can find documentation for Gmail's API at https://developers.google.com/gmail/api/

  ### Client support is planned for:

  * [x] Threads
  * [x] Messages
  * [x] Labels
  * [ ] Drafts
  * [ ] History

  As of now the library doesn't do the initial auth generation for you; you'll
  need to create an app on the [Google Developer
  Console](https://console.developers.google.com/) to get a client ID and secret
  and authorize a user to get an authorization code, which you can trade for an
  access token.

  The library will however, when you supply a refresh token, use that to refresh
  an expired access token for you. Take a look in the `dev.exs.sample` config
  file to see what your config should look like.
  """

  use Application
  alias Gmail.Thread

  @spec search(String.t) :: {atom, [Thread.t]}
  defdelegate search(query), to: Thread

  def start(_type, _args) do
    {:ok, _pid} = Gmail.Supervisor.start_link
    {:ok, self}
  end

  def stop(_args) do
    # noop
  end

end
