defmodule Haul.Content.GalleryItem do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  postgres do
    table "gallery_items"
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

    attribute :before_image_url, :string do
      allow_nil? false
      public? true
    end

    attribute :after_image_url, :string do
      allow_nil? false
      public? true
    end

    attribute :caption, :string do
      allow_nil? true
      public? true
    end

    attribute :alt_text, :string do
      allow_nil? true
      public? true
    end

    attribute :sort_order, :integer do
      allow_nil? false
      default 0
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

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read, :destroy]

    create :add do
      accept [:before_image_url, :after_image_url, :caption, :alt_text, :sort_order, :featured]
    end

    update :edit do
      accept [:caption, :alt_text, :sort_order, :featured, :active]
    end
  end
end
