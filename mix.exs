defmodule Actux.MixProject do
  use Mix.Project

  def project do
    [
      app: :actux,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:httpoison, :poison]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"}
    ]
  end
end
