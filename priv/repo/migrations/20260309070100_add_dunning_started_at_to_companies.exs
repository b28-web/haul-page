defmodule Haul.Repo.Migrations.AddDunningStartedAtToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :dunning_started_at, :utc_datetime, null: true
    end
  end
end
