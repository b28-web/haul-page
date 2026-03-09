defmodule Haul.Repo.TenantMigrations.AddEndorsementSortOrder do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:endorsements, prefix: prefix()) do
      add :sort_order, :integer, null: false, default: 0
    end
  end

  def down do
    alter table(:endorsements, prefix: prefix()) do
      remove :sort_order
    end
  end
end
