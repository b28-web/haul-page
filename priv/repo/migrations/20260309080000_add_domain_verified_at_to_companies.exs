defmodule Haul.Repo.Migrations.AddDomainVerifiedAtToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :domain_verified_at, :utc_datetime
    end
  end
end
