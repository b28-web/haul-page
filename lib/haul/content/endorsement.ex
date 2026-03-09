defmodule Haul.Content.Endorsement do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  paper_trail do
    change_tracking_mode :changes_only
  end

  postgres do
    table "endorsements"
    repo Haul.Repo

    multitenancy do
      strategy :context
    end
  end

  multitenancy do
    strategy :context
  end

  attributes do
    uuid_primary_key :id

    attribute :customer_name, :string do
      allow_nil? false
      public? true
    end

    attribute :quote_text, :string do
      allow_nil? false
      public? true
    end

    attribute :star_rating, :integer do
      allow_nil? true
      public? true
      constraints min: 1, max: 5
    end

    attribute :source, Haul.Content.Endorsement.Source do
      allow_nil? true
      public? true
    end

    attribute :date, :date do
      allow_nil? true
      public? true
    end

    attribute :featured, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :active, :boolean do
      allow_nil? false
      default true
      public? true
    end

    attribute :sort_order, :integer do
      allow_nil? false
      default 0
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :job, Haul.Operations.Job do
      allow_nil? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :add do
      accept [:customer_name, :quote_text, :star_rating, :source, :date, :featured, :sort_order]
    end

    update :edit do
      accept [
        :customer_name,
        :quote_text,
        :star_rating,
        :source,
        :date,
        :featured,
        :active,
        :sort_order
      ]
    end
  end
end
