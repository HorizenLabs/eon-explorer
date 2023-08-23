import Config

# Print only warnings and errors during test

config :logger, :console, level: :error

config :logger, :ecto,
  level: :error,
  path: Path.absname("logs/test/ecto.log")

config :logger, :error, path: Path.absname("logs/test/error.log")

config :explorer, Explorer.ExchangeRates,
  source: Explorer.ExchangeRates.Source.NoOpSource,
  store: :none
