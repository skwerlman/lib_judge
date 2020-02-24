defmodule ArchiveChallenges.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.0.1"
  @repo "https://github.com/skwerlman/archive_challenges"

  def project do
    [
      app: :lib_judge,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:stream_data, "~> 0.4", only: :test},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~>1.0.0-rc.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
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
end
