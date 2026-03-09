defmodule Haul.Admin.AdminToken do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Admin,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource]

  postgres do
    table "admin_tokens"
    repo Haul.Repo
  end
end
