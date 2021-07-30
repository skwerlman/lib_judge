defmodule ArchiveChallenges.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.4.0"
  @repo "https://github.com/skwerlman/lib_judge"

  def project do
    [
      app: :lib_judge,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {LibJudge, []}
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.8"},
      {:floki, "~> 0.31"},
      {:propcheck, "~> 1.4", only: :test},
      {:stream_data, "~> 0.5", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @repo,
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end

  defp dialyzer do
    plt =
      case Mix.env() do
        # this fixes a failure when dialyxir is run in a test env
        :test ->
          [:ex_unit]

        _ ->
          []
      end

    [
      plt_add_apps: plt,
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions,
        :no_opaque,
        :underspecs
      ]
    ]
  end

  # include models for property tests
  defp elixirc_paths(:test), do: ["lib", "test/models"]
  defp elixirc_paths(_), do: ["lib"]
end
