use Mix.Config

config :bypass, enable_debug_log: false

if File.exists?("./config/test.local.exs") do
  import_config "test.local.exs"
end


