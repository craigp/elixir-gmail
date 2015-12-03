use Mix.Config

if File.exists?("./config/test.local.exs") do
  import_config "test.local.exs"
end


