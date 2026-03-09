defmodule Haul.Repo.Migrations.AddOnboardingCompleteToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :onboarding_complete, :boolean, default: false, null: false
    end
  end
end
