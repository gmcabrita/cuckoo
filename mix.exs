defmodule Cuckoo.Mixfile do
  use Mix.Project

  @description """
  Cuckoo is a pure Elixir implementation of Cuckoo Filters.
  """

  def project do
    [app: :cuckoo,
     version: "0.0.1",
     elixir: "~> 1.0",
     description: @description,
     deps: deps,
     aliases: [dialyze: "dialyze --unmatched-returns --error-handling --race-conditions --underspecs"],
     test_coverage: [tool: Coverex.Task, coveralls: true]
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:coverex, "~> 1.0.0", only: :test},
     {:murmur, "~> 0.2"}
    ]
  end
end
