defmodule Haul.AI.CostEntry do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.AI.Domain,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ai_cost_entries"
    repo Haul.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :conversation_id, :uuid do
      allow_nil? true
      public? true
    end

    attribute :function_name, :string do
      allow_nil? false
      public? true
    end

    attribute :model, :string do
      allow_nil? false
      public? true
    end

    attribute :input_tokens, :integer do
      allow_nil? false
      public? true
    end

    attribute :output_tokens, :integer do
      allow_nil? false
      public? true
    end

    attribute :estimated_cost_usd, :decimal do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
  end

  actions do
    defaults [:read, :destroy]

    create :record do
      accept [
        :conversation_id,
        :function_name,
        :model,
        :input_tokens,
        :output_tokens,
        :estimated_cost_usd
      ]
    end

    read :for_conversation do
      argument :conversation_id, :uuid, allow_nil?: false
      filter expr(conversation_id == ^arg(:conversation_id))
    end

    read :for_date_range do
      argument :start_at, :utc_datetime, allow_nil?: false
      argument :end_at, :utc_datetime, allow_nil?: false
      filter expr(inserted_at >= ^arg(:start_at) and inserted_at < ^arg(:end_at))
    end

    read :with_conversation do
      filter expr(not is_nil(conversation_id))
    end
  end
end
