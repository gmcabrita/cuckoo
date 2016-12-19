defmodule Cuckoo.Mixfile do
  use Mix.Project

  @description """
  Cuckoo is a pure Elixir implementation of Cuckoo Filters.
  """
  @github "https://github.com/gmcabrita/cuckoo"

  def project do
    [
      app: :cuckoo,
      name: "Cuckoo",
      source_url: @github,
      homepage_url: nil,
      version: "1.0.1-dev",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: @description,
      package: package(),
      deps: deps(),
      dialyzer: [
        flags: ["-Wunmatched_returns", "-Werror_handling", "-Wrace_conditions", "-Wunderspecs"]
      ],
      test_coverage: [tool: ExCoveralls],
      docs: docs()
    ]
  end

  def application do
    []
  end

  defp docs do
    [
      main: "readme",
      logo: nil,
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:murmur, "~> 1.0"},
      {:excoveralls, "~> 0.5", only: :docs, runtime: false},
      {:ex_doc, "~> 0.14", only: :docs, runtime: false},
      {:inch_ex, ">= 0.0.0", only: :docs, runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 0.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Gonçalo Cabrita"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end
end
