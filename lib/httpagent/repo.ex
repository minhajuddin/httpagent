defmodule HA.Repo do
  use Ecto.Repo,
    otp_app: :httpagent,
    adapter: Ecto.Adapters.Postgres
end
