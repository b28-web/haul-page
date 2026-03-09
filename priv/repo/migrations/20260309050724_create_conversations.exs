defmodule Haul.Repo.Migrations.CreateConversations do
  @moduledoc """
  Creates the conversations table for AI chat persistence.
  """

  use Ecto.Migration

  def up do
    create table(:conversations, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :session_id, :uuid, null: false
      add :messages, {:array, :map}, null: false, default: []
      add :extracted_profile, :map
      add :status, :text, null: false, default: "active"
      add :company_id, :uuid

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
    end

    create unique_index(:conversations, [:session_id], name: "conversations_unique_session_index")
    create index(:conversations, [:company_id])
    create index(:conversations, [:status, :inserted_at])
  end

  def down do
    drop_if_exists unique_index(:conversations, [:session_id],
                     name: "conversations_unique_session_index"
                   )

    drop table(:conversations)
  end
end
