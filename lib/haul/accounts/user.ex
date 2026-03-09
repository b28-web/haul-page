defmodule Haul.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo Haul.Repo

    multitenancy do
      strategy :context
    end
  end

  authentication do
    tokens do
      enabled? true
      token_resource Haul.Accounts.Token
      require_token_presence_for_authentication? true

      signing_secret fn _, _ ->
        Application.fetch_env(:haul, :token_signing_secret)
      end
    end

    strategies do
      password :password do
        identity_field :email

        resettable do
          sender fn _user, _token, _opts ->
            # TODO: implement password reset email via Haul.Mailer
            :ok
          end
        end
      end

      magic_link :magic_link do
        identity_field :email
        require_interaction? true

        sender fn _user, _token, _opts ->
          # TODO: implement magic link email via Haul.Mailer
          :ok
        end
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

    attribute :role, Haul.Accounts.User.Role do
      allow_nil? false
      default :crew
      public? true
    end

    attribute :phone, :string do
      allow_nil? true
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end

    attribute :active, :boolean do
      allow_nil? false
      default true
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

    update :update_profile do
      accept [:name, :phone]
    end

    update :update_user do
      accept [:name, :phone, :role, :active]
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    bypass action(:sign_in_with_password) do
      authorize_if always()
    end

    bypass action(:sign_in_with_magic_link) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
      authorize_if actor_attribute_equals(:role, :owner)
      authorize_if actor_attribute_equals(:role, :dispatcher)
    end

    policy action(:update_profile) do
      authorize_if expr(id == ^actor(:id))
    end

    policy action(:update_user) do
      authorize_if actor_attribute_equals(:role, :owner)
    end

    policy action_type(:create) do
      authorize_if actor_attribute_equals(:role, :owner)
      authorize_if AshAuthentication.Checks.AshAuthenticationInteraction
    end

    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, :owner)
    end
  end
end
