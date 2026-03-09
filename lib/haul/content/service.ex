defmodule Haul.Content.Service do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  paper_trail do
    change_tracking_mode :changes_only
  end

  postgres do
    table "services"
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

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      allow_nil? false
      public? true
    end

    attribute :icon, :string do
      allow_nil? false
      public? true
    end

    attribute :sort_order, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :active, :boolean do
      allow_nil? false
      default true
      public? true
    end

    attribute :category, :atom do
      allow_nil? true
      public? true

      constraints one_of: [
                    :junk_removal,
                    :cleanouts,
                    :yard_waste,
                    :repairs,
                    :assembly,
                    :moving_help,
                    :other
                  ]
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read, :destroy]

    create :add do
      accept [:title, :description, :icon, :sort_order, :category]
    end

    update :edit do
      accept [:title, :description, :icon, :sort_order, :active, :category]
    end
  end

  preparations do
    prepare build(sort: [sort_order: :asc])
  end
end
