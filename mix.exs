defmodule Gmail.Mixfile do
  use Mix.Project

  def project do
    [app: :gmail,
     version: "0.0.2",
     elixir: "~> 1.0",
     deps: deps,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test],
     description: "A Gmail API client for Elixir",
     package: package]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.7.3"},
      {:poison, "~> 1.5.0"},
      {:mock, "~> 0.1.1"},
      {:timex, "~> 0.19.3"},
      {:excoveralls, "~> 0.4.2"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      licenses: ["MIT"],
      maintainers: ["Craig Paterson"],
      links: %{"Github" => "https://github.com/craigp/elixir-gmail"}]
  end

end
