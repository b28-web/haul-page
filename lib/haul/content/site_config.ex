defmodule Haul.Content.SiteConfig do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  paper_trail do
    change_tracking_mode :changes_only
  end

  postgres do
    table "site_configs"
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

    attribute :business_name, :string do
      allow_nil? false
      public? true
    end

    attribute :phone, :string do
      allow_nil? false
      public? true
    end

    attribute :email, :string do
      allow_nil? true
      public? true
    end

    attribute :tagline, :string do
      allow_nil? true
      public? true
    end

    attribute :service_area, :string do
      allow_nil? true
      public? true
    end

    attribute :address, :string do
      allow_nil? true
      public? true
    end

    attribute :coupon_text, :string do
      allow_nil? true
      default "10% OFF"
      public? true
    end

    attribute :meta_description, :string do
      allow_nil? true
      public? true
    end

    attribute :primary_color, :string do
      allow_nil? true
      default "#0f0f0f"
      public? true
    end

    attribute :logo_url, :string do
      allow_nil? true
      public? true
    end

    attribute :owner_name, :string do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read]

    create :create_default do
      accept [
        :business_name,
        :phone,
        :email,
        :tagline,
        :service_area,
        :address,
        :coupon_text,
        :meta_description,
        :primary_color,
        :logo_url,
        :owner_name
      ]
    end

    update :edit do
      accept [
        :business_name,
        :phone,
        :email,
        :tagline,
        :service_area,
        :address,
        :coupon_text,
        :meta_description,
        :primary_color,
        :logo_url,
        :owner_name
      ]
    end
  end

  code_interface do
    define :current, action: :read
    define :edit, action: :edit
  end
end
