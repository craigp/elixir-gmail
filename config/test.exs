use Mix.Config

# config :bypass, enable_debug_log: true

if File.exists?("./config/test.local.exs") do
  import_config "test.local.exs"
end


