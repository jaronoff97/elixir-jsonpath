defmodule JsonPath.MixProject do
  use Mix.Project

  def project do
    [
      app: :jsonpath,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      compilers: [:yecc, :leex] ++ Mix.compilers(),
      erlc_paths: ["lib/token"],
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "1.4.4", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "This library supports querying nested maps and lists using JSONPath syntax.\n
    It currently implements a **partial subset of [RFC 9535](https://www.rfc-editor.org/rfc/rfc9535.html)** and passes **400/702 compliance tests**."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/jaronoff97/elixir-jsonpath"}
    ]
  end
end
