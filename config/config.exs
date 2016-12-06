use Mix.Config

config :gmail, :thread,
  pool_size: 100

config :gmail, :message,
  pool_size: 100

path = __DIR__ |> Path.expand |> Path.join("#{Mix.env}.exs")
if File.exists?(path), do: import_config "#{Mix.env}.exs"
