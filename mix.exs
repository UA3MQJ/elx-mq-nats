defmodule MQNATS.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :mqnats,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:nats, git: "https://github.com/nats-io/elixir-nats.git"}
    ]
  end
end
