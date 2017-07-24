defmodule Mqnats.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :mqnats,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:nats, git: "https://github.com/nats-io/elixir-nats.git"}
    ]
  end

  defp description do
    """
    MMQL module for NATS
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Alexey Bolshakov"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/UA3MQJ/elx-mq-nats"}
    ]
  end
end
