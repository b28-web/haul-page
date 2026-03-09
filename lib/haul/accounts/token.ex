defmodule Haul.Accounts.Token do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "tokens"
    repo Haul.Repo

    multitenancy do
      strategy :context
    end
  end
end
