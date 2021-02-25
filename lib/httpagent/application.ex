defmodule HA.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # HTTP
      {Registry, keys: :unique, name: HTTP.Registry},
      # Start the Ecto repository
      HA.Repo,
      # Start the Telemetry supervisor
      HAWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HA.PubSub},
      {Finch,
       name: HAFinch,
       pools: %{
         default: Application.get_env(:httpagent, :finch_default_pool_opts)
       }},
      # Start the Endpoint (http/https)
      HAWeb.Endpoint
      # Start a worker by calling: HA.Worker.start_link(arg)
      # {HA.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HA.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HAWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
