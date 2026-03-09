defmodule Haul.Repo.Migrations.AddDomainStatusToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :domain_status, :string
    end
  end
end
