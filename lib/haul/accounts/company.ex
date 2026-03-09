defmodule Haul.Accounts.Company do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "companies"
    repo Haul.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :timezone, :string do
      allow_nil? false
      default "Etc/UTC"
      public? true
    end

    attribute :subscription_plan, :atom do
      allow_nil? false
      default :starter
      constraints one_of: [:starter, :pro, :business, :dedicated]
      public? true
    end

    attribute :stripe_customer_id, :string do
      allow_nil? true
      public? true
    end

    attribute :stripe_subscription_id, :string do
      allow_nil? true
      public? true
    end

    attribute :domain, :string do
      allow_nil? true
      public? true
    end

    attribute :domain_status, :atom do
      allow_nil? true
      constraints one_of: [:pending, :verified, :provisioning, :active]
      public? true
    end

    attribute :onboarding_complete, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :dunning_started_at, :utc_datetime do
      allow_nil? true
      public? true
    end

    attribute :domain_verified_at, :utc_datetime do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_slug, [:slug]
    identity :unique_domain, [:domain]
  end

  actions do
    defaults [:read]

    create :create_company do
      accept [:name, :slug, :timezone, :subscription_plan, :domain]

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :slug) do
          nil ->
            name = Ash.Changeset.get_attribute(changeset, :name) || ""

            slug =
              name
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9]+/, "-")
              |> String.trim("-")

            Ash.Changeset.force_change_attribute(changeset, :slug, slug)

          _slug ->
            changeset
        end
      end

      change Haul.Accounts.Changes.ProvisionTenant
    end

    update :update_company do
      accept [
        :name,
        :timezone,
        :subscription_plan,
        :stripe_customer_id,
        :stripe_subscription_id,
        :domain,
        :domain_status,
        :domain_verified_at,
        :onboarding_complete,
        :dunning_started_at
      ]
    end

    read :by_stripe_customer_id do
      argument :stripe_customer_id, :string, allow_nil?: false
      get? true

      filter expr(stripe_customer_id == ^arg(:stripe_customer_id))
    end
  end
end
