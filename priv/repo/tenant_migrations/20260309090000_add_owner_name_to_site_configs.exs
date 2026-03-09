defmodule Haul.Repo.TenantMigrations.AddOwnerNameToSiteConfigs do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:site_configs, prefix: prefix()) do
      add :owner_name, :string
    end
  end

  def down do
    alter table(:site_configs, prefix: prefix()) do
      remove :owner_name
    end
  end
end
