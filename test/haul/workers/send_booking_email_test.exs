defmodule Haul.Workers.SendBookingEmailTest do
  use Haul.DataCase, async: false
  use Oban.Testing, repo: Haul.Repo

  import Swoosh.TestAssertions

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Operations.Job
  alias Haul.Workers.SendBookingEmail

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
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Test Hauling #{System.unique_integer([:positive])}"
      })
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(:create_from_online_booking, @valid_attrs, tenant: tenant)
      |> Ash.create()

    %{tenant: tenant, job: job}
  end

  test "sends operator alert and customer confirmation", %{tenant: tenant, job: job} do
    :ok = perform_job(SendBookingEmail, %{"job_id" => job.id, "tenant" => tenant})

    # Operator alert
    assert_email_sent(subject: "New booking from Jane Doe")

    # Customer confirmation
    operator = Application.get_env(:haul, :operator, [])
    assert_email_sent(subject: "Booking received — #{operator[:business_name]}")
  end

  test "skips customer confirmation when no email", %{tenant: tenant} do
    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(
        :create_from_online_booking,
        Map.delete(@valid_attrs, :customer_email),
        tenant: tenant
      )
      |> Ash.create()

    :ok = perform_job(SendBookingEmail, %{"job_id" => job.id, "tenant" => tenant})

    # Operator alert sent
    assert_email_sent(subject: "New booking from Jane Doe")

    # No customer confirmation
    operator = Application.get_env(:haul, :operator, [])
    expected_subject = "Booking received — #{operator[:business_name]}"
    refute_email_sent(subject: ^expected_subject)
  end

  test "returns :ok when job not found", %{tenant: tenant} do
    assert :ok ==
             perform_job(SendBookingEmail, %{
               "job_id" => Ash.UUID.generate(),
               "tenant" => tenant
             })
  end
end
