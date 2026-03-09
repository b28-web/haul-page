defmodule Haul.Admin.AdminUser do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Admin,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "admin_users"
    repo Haul.Repo
  end

  authentication do
    tokens do
      enabled? true
      token_resource Haul.Admin.AdminToken
      require_token_presence_for_authentication? true

      signing_secret fn _, _ ->
        Application.fetch_env(:haul, :token_signing_secret)
      end
    end

    strategies do
      password :password do
        identity_field :email
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? true
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end

    attribute :setup_token_hash, :string do
      allow_nil? true
      sensitive? true
    end

    attribute :setup_completed, :boolean do
      allow_nil? false
      default false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
  end

  actions do
    defaults [:read]

    create :create_bootstrap do
      accept [:email, :name, :setup_token_hash]
      argument :setup_token_hash_value, :string

      change set_attribute(:setup_completed, false)

      change fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :setup_token_hash_value) do
          nil -> changeset
          hash -> Ash.Changeset.force_change_attribute(changeset, :setup_token_hash, hash)
        end
      end
    end

    update :complete_setup do
      accept [:hashed_password]

      change set_attribute(:setup_completed, true)
      change set_attribute(:setup_token_hash, nil)
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    bypass action(:sign_in_with_password) do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if always()
    end

    policy action(:create_bootstrap) do
      authorize_if always()
    end

    policy action(:complete_setup) do
      authorize_if always()
    end
  end
end
