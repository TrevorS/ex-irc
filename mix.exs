defmodule ExIRC.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_irc,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExIRC.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.4"},
      {:credo, "~> 0.8.10"}
    ]
  end
end
