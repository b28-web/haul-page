defmodule Haul.Repo do
  use Ecto.Repo,
    otp_app: :haul,
    adapter: Ecto.Adapters.Postgres
end
