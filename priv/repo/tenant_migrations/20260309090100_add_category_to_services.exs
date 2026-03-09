defmodule Haul.Repo.TenantMigrations.AddCategoryToServices do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:services, prefix: prefix()) do
      add :category, :string
    end
  end

  def down do
    alter table(:services, prefix: prefix()) do
      remove :category
    end
  end
end
