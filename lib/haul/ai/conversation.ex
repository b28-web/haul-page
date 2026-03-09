defmodule Haul.AI.Conversation do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.AI.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "conversations"
    repo Haul.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :session_id, :uuid do
      allow_nil? false
      public? true
    end

    attribute :messages, {:array, :map} do
      allow_nil? false
      default []
      public? true
    end

    attribute :extracted_profile, :map do
      allow_nil? true
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :active
      public? true
      constraints one_of: [:active, :completed, :abandoned, :provisioning, :failed]
    end

    attribute :company_id, :uuid do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_session, [:session_id]
  end

  actions do
    defaults [:read, :destroy]

    create :start do
      accept [:session_id]
    end

    read :by_session_id do
      argument :session_id, :uuid, allow_nil?: false
      filter expr(session_id == ^arg(:session_id))
    end

    read :stale_active do
      argument :cutoff, :utc_datetime, allow_nil?: false
      filter expr(status == :active and inserted_at < ^arg(:cutoff))
    end

    read :old_abandoned do
      argument :cutoff, :utc_datetime, allow_nil?: false
      filter expr(status == :abandoned and updated_at < ^arg(:cutoff))
    end

    update :add_message do
      require_atomic? false
      argument :message, :map, allow_nil?: false
      change Haul.AI.Changes.AppendMessage
    end

    update :save_profile do
      accept [:extracted_profile]
    end

    update :link_to_company do
      accept [:company_id]
      change set_attribute(:status, :completed)
    end

    update :mark_abandoned do
      change set_attribute(:status, :abandoned)
    end

    update :mark_provisioning do
      change set_attribute(:status, :provisioning)
    end

    update :mark_failed do
      change set_attribute(:status, :failed)
    end
  end
end
