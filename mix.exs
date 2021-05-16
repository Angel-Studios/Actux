defmodule Actux.MixProject do
  use Mix.Project

  def project do
    [
      app: :actux,
      version: "0.3.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:tesla, :jason]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:plug, "~> 1.11"},
      {:tesla, "~> 1.4"},
      {:ua_parser, "~> 1.7"},
    ]
  end
end
