elixir-gmail
============
[![Build Status](https://secure.travis-ci.org/craigp/elixir-gmail.png?branch=master "Build Status")](http://travis-ci.org/craigp/elixir-gmail)
[![Coverage Status](https://coveralls.io/repos/craigp/elixir-gmail/badge.svg?branch=master&service=github)](https://coveralls.io/github/craigp/elixir-gmail?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/gmail.svg)](https://hex.pm/packages/gmail)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/gmail.svg)](https://hex.pm/packages/gmail)
[![Inline docs](http://inch-ci.org/github/craigp/elixir-gmail.svg?branch=master&style=flat)](http://inch-ci.org/github/craigp/elixir-gmail)

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

## API Support

* [ ] Threads
  * [x] `get`
  * [x] `list`
  * [ ] `modify`
  * [x] `delete`
  * [x] `trash`
  * [x] `untrash`
* [ ] Messages
  * [x] `delete`
  * [x] `get`
  * [ ] `insert`
  * [x] `list`
  * [x] `modify`
  * [ ] `send`
  * [x] `trash`
  * [x] `untrash`
  * [ ] `import`
  * [ ] `batchDelete`
* [x] Labels
  * [x] `create`
  * [x] `delete`
  * [x] `list`
  * [x] `update`
  * [x] `get`
  * [x] `update`
  * [x] `patch`
* [ ] Drafts
  * [x] `list`
  * [x] `get`
  * [x] `delete`
  * [ ] `update`
  * [ ] `create`
  * [x] `send`
  * [ ] `send` (with upload)
* [x] History
  * [x] `list`
* [x] Attachments
  * [x] `get` (thanks to @killtheliterate)

## Auth

As of now the library doesn't do the initial auth generation for you; you'll
need to create an app on the [Google Developer
Console](https://console.developers.google.com/) to get a client ID and secret
and authorize a user to get an authorization code, which you can trade for an
access token.

The library will however, when you supply a refresh token, use that to refresh
an expired access token for you. Take a look in the `dev.exs.sample` config
file to see what your config should look like.

## TODO

* [x] Stop mocking HTTP requests and use [Bypass](https://github.com/PSPDFKit-labs/bypass) instead
* [x] Add format option when fetching threads
* [x] .. and messages
* [ ] .. and drafts
* [ ] Batched requests
* [ ] Document the config (specifically pool size)

