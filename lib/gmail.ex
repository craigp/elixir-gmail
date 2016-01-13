defmodule Gmail do

  alias Gmail.Thread

  @moduledoc """
  A simple Gmail REST API client for Elixir, mostly built as a learning exercise.

  You can find documentation for Gmail's API at https://developers.google.com/gmail/api/

  At this stage the client supports API endpoints for:
  - threads
  - messages
  - labels

  Still missing is support for:
  - drafts
  - history

  As of now the library doesn't do the initial auth generation for you; you'll
  need to create an app on the [Google Developer
  Console](https://console.developers.google.com/) to get a client ID and secret
  and authorize a user to get an authorization code, which you can trade for an
  access token.

  The library will however, when you supply a refresh token, use that to refresh
  an expired access token for you. Take a look in the `dev.exs.sample` config
  file to see what your config should look like.
  """

  @spec search(String.t) :: {atom, [Thread.t]}
  defdelegate search(query), to: Thread

end
