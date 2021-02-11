# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :httpagent,
  namespace: HA,
  ecto_repos: [HA.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :httpagent, HAWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "a9iIPc4EMo3jkN38KTm2QqMeCoLTaQwZ4PM5n5py0A1NjVvRsv22iV0CQ8D4wQsC",
  render_errors: [view: HAWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HA.PubSub,
  live_view: [signing_salt: "vCcGeqC0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
