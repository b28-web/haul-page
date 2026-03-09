defmodule Haul.Operations.Changes.EnqueueNotificationsTest do
  use Haul.DataCase, async: false
  use Oban.Testing, repo: Haul.Repo

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Operations.Job

  @valid_attrs %{
    customer_name: "Jane Doe",
    customer_phone: "(555) 987-6543",
    customer_email: "jane@example.com",
    address: "123 Main St, Anytown, USA",
    item_description: "Old couch and two mattresses"
  }

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Test Hauling"})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{tenant: tenant}
  end

  test "enqueues email and SMS workers on job creation", %{tenant: tenant} do
    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(:create_from_online_booking, @valid_attrs, tenant: tenant)
      |> Ash.create()

    assert_enqueued(
      worker: Haul.Workers.SendBookingEmail,
      args: %{"job_id" => job.id, "tenant" => tenant}
    )

    assert_enqueued(
      worker: Haul.Workers.SendBookingSMS,
      args: %{"job_id" => job.id, "tenant" => tenant}
    )
  end
end
