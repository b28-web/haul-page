defmodule Haul.Repo.TenantMigrations.FixGalleryVersionsCascade do
  @moduledoc """
  Remove FK constraint from gallery_items_versions to gallery_items.
  PaperTrail creates a version record during destroy, but the FK check
  fails because the source record is deleted in the same transaction.
  The version_source_id column is kept as a plain UUID.
  """
  use Ecto.Migration

  def up do
    drop constraint(:gallery_items_versions, "gallery_items_versions_version_source_id_fkey",
           prefix: prefix())
  end

  def down do
    alter table(:gallery_items_versions, prefix: prefix()) do
      modify :version_source_id,
             references(:gallery_items,
               column: :id,
               name: "gallery_items_versions_version_source_id_fkey",
               type: :uuid,
               prefix: prefix()
             )
    end
  end
end
