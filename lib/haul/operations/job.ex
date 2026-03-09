defmodule Haul.Operations.Job do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Operations,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  postgres do
    table "jobs"
    repo Haul.Repo

    multitenancy do
      strategy :context
    end
  end

  multitenancy do
    strategy :context
  end

  state_machine do
    initial_states [:lead]
    default_initial_state :lead

    # Transitions will be added as future tickets implement state changes.
    # Each transition requires a corresponding update action.
  end

  attributes do
    uuid_primary_key :id

    attribute :customer_name, :string do
      allow_nil? false
      public? true
    end

    attribute :customer_phone, :string do
      allow_nil? false
      public? true
    end

    attribute :customer_email, :string do
      allow_nil? true
      public? true
    end

    attribute :address, :string do
      allow_nil? false
      public? true
    end

    attribute :item_description, :string do
      allow_nil? false
      public? true
    end

    attribute :preferred_dates, {:array, :date} do
      allow_nil? true
      default []
      public? true
    end

    attribute :notes, :string do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [:read]

    create :create_from_online_booking do
      accept [:customer_name, :customer_phone, :customer_email, :address, :item_description, :preferred_dates, :notes]
    end
  end
end
