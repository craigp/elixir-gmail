defmodule Gmail.Mixfile do
  use Mix.Project

  def project do
    [app: :gmail,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     description: "A Gmail API client for Elixir",
     package: package]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [ {:httpoison, "~> 0.5"}, {:poison, "~> 1.2"}, {:mock, "~> 0.1"}, {:timex, "~> 0.13"} ]
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      contributors: ["Craig Paterson"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/craigp/elixir-gmail"}]
  end

end
