defmodule Actux.MixProject do
  use Mix.Project

  def project do
    [
      app: :actux,
      version: "0.2.0",
      elixir: "~> 1.6",
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
      {:tesla, "~> 1.2.1"},
      {:jason, "~> 1.1"}
    ]
  end
end
