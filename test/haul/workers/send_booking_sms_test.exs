defmodule Haul.Workers.SendBookingSMSTest do
  use Haul.DataCase, async: false
  use Oban.Testing, repo: Haul.Repo

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Operations.Job
  alias Haul.Workers.SendBookingSMS

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

    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(:create_from_online_booking, @valid_attrs, tenant: tenant)
      |> Ash.create()

    %{tenant: tenant, job: job}
  end

  test "sends SMS to operator", %{tenant: tenant, job: job} do
    :ok = perform_job(SendBookingSMS, %{"job_id" => job.id, "tenant" => tenant})

    assert_received {:sms_sent, message}
    assert message.body =~ "Jane Doe"
    assert message.body =~ "(555) 987-6543"
    assert message.body =~ "123 Main St"
  end

  test "returns :ok when job not found", %{tenant: tenant} do
    assert :ok ==
             perform_job(SendBookingSMS, %{
               "job_id" => Ash.UUID.generate(),
               "tenant" => tenant
             })
  end
end
