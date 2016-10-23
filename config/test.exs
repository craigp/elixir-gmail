use Mix.Config

config :bypass, enable_debug_log: false

config :gmail, :oauth2,
  client_id: "fake-client-id",
  client_secret: "fake-client-secret"

config :gmail, :thread,
  pool: 100

config :gmail, :message,
  pool: 100
