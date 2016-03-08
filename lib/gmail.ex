defmodule Gmail do

  @moduledoc """
  A simple Gmail REST API client for Elixir.

  You can find the hex package [here](https://hex.pm/packages/gmail), and the docs [here](http://hexdocs.pm/gmail).

  You can find documentation for Gmail's API at https://developers.google.com/gmail/api/

  ## Usage

  First, add the client to your `mix.exs` dependencies:

  ```elixir
  def deps do
  [{:gmail, "~> 0.1"}]
  end
  ```

  Then run `$ mix do deps.get, compile` to download and compile your dependencies.

  Finally, add the `:gmail` application as your list of applications in `mix.exs`:

  ```elixir
  def application do
  [applications: [:logger, :gmail]]
  end
  ```

  Before you can work with mail for a user you'll need to start a process for them.

  ```elixir
  {:ok, pid} = Gmail.User.start_mail("user@example.com", "user-refresh-token")
  ```

  When a user process starts it will automatically fetch a new access token for that user. Then
  you can start playing with mail:

  ```elixir
  # fetch a list of threads
  {:ok, threads, next_page_token} = Gmail.User.threads("user@example.com")

  # fetch the next page of threads using a page token
  {:ok, _, _} = Gmail.User.threads("user@example.com", %{page_token: next_page_token})

  # fetch a thread by ID
  {:ok, thread} = Gmail.User.thread("user@example.com", "1233454566")

  # fetch a list of labels
  {:ok, labels} = Gmail.User.labels("user@example.com")
  ```

  Check the docs for a more complete list of functionality.
  """

  use Application
  # alias Gmail.Thread

  # @spec search(String.t) :: {atom, [Thread.t]}
  # defdelegate search(query), to: Thread

  def start(_type, _args) do
    {:ok, _pid} = Gmail.Supervisor.start_link
    {:ok, self}
  end

  def stop(_args) do
    # noop
  end

end
