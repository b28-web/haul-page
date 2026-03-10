defmodule Haul.Accounts.Changes.ProvisionTenant do
  @moduledoc """
  After a Company is created, provisions a dedicated Postgres schema
  and runs tenant migrations into it.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    if Application.get_env(:haul, :skip_tenant_provision) do
      changeset
    else
      Ash.Changeset.after_action(changeset, fn _changeset, company ->
        schema = tenant_schema(company.slug)

        Ecto.Adapters.SQL.query!(Haul.Repo, "CREATE SCHEMA IF NOT EXISTS \"#{schema}\"")

        AshPostgres.MultiTenancy.migrate_tenant(schema, Haul.Repo)

        {:ok, company}
      end)
    end
  end

  @doc "Derives the Postgres schema name from a company slug."
  def tenant_schema(slug), do: "tenant_#{slug}"
end
