defmodule MixCmake.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_cmake,
      version: "0.1.5",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "mix_cmake",
      source_url: "https://github.com/shoz-f/mix_cmake.git",

      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Mix task for Cmake build tool."
  end

  defp package() do
    [
      name: "mix_cmake",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/shoz-f/mix_cmake.git"},
      files: ~w(lib mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
      ],
    ]
  end
end
