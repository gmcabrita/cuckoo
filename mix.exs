defmodule Cuckoo.Mixfile do
  use Mix.Project

  @description """
  Cuckoo is a pure Elixir implementation of Cuckoo Filters.
  """

  def project do
    [app: :cuckoo,
     version: "0.3.1",
     elixir: "~> 1.0",
     description: @description,
     package: package,
     deps: deps,
     aliases: [
        dialyze: "dialyze \
                    --unmatched-returns \
                    --error-handling \
                    --race-conditions \
                    --underspecs"
      ],
     test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:excoveralls, "~> 0.3", only: :docs},
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.10", only: :docs},
     {:inch_ex, only: :docs},
     {:murmur, "~> 0.2"}
    ]
  end

  defp package do
  	[
        files: ["lib", "mix.exs", "README.md", "LICENSE"],
        maintainers: ["Gonçalo Cabrita"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/gmcabrita/cuckoo"}
    ]
  end
end
