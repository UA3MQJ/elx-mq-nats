use Mix.Config

# default option for nats
config :mqnats,
  mqnats: %{
    host: "127.0.0.1",
    port: 4222,
    timeout: 6000
  }
