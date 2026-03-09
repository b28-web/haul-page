defmodule HaulWeb.PaymentLiveTest do
  use HaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.Company
  alias Haul.Operations.Job

  setup do
    operator = Application.get_env(:haul, :operator)
    operator_slug = operator[:slug] || "default"

    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{name: "Junk & Handy", slug: operator_slug})
      |> Ash.create()

    tenant = ProvisionTenant.tenant_schema(company.slug)

    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(:create_from_online_booking, %{
        customer_name: "Jane Doe",
        customer_phone: "(555) 123-4567",
        customer_email: "jane@example.com",
        address: "123 Main St",
        item_description: "Old couch and two chairs"
      })
      |> Ash.create(tenant: tenant)

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

    %{tenant: tenant, job: job}
  end

  test "renders payment page for valid job", %{conn: conn, job: job} do
    {:ok, _view, html} = live(conn, "/pay/#{job.id}")

    assert html =~ "Complete Payment"
    assert html =~ "Jane Doe"
    assert html =~ "123 Main St"
    assert html =~ "$50.00"
  end

  test "renders not found for invalid job_id", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/pay/#{Ash.UUID.generate()}")

    assert html =~ "Job Not Found"
  end

  test "assigns client_secret from payment intent", %{conn: conn, job: job} do
    {:ok, view, _html} = live(conn, "/pay/#{job.id}")

    assert view |> element("#stripe-payment") |> render() =~ "data-client-secret"
  end

  test "handles payment_confirmed event", %{conn: conn, job: job, tenant: tenant} do
    {:ok, view, _html} = live(conn, "/pay/#{job.id}")

    render_hook(view, "payment_confirmed", %{"payment_intent_id" => "pi_test_confirmed"})

    html = render(view)
    assert html =~ "Payment Received"

    {:ok, updated_job} = Ash.get(Job, job.id, tenant: tenant)
    assert updated_job.payment_intent_id == "pi_test_confirmed"
  end

  test "handles payment_failed event", %{conn: conn, job: job} do
    {:ok, view, _html} = live(conn, "/pay/#{job.id}")

    render_hook(view, "payment_failed", %{"error" => "Card declined"})

    html = render(view)
    assert html =~ "Payment Failed"
    assert html =~ "Card declined"
  end

  test "shows already paid for job with payment_intent_id", %{
    conn: conn,
    job: job,
    tenant: tenant
  } do
    {:ok, _updated} =
      Ash.update(job, %{payment_intent_id: "pi_already_paid"},
        action: :record_payment,
        tenant: tenant
      )

    {:ok, _view, html} = live(conn, "/pay/#{job.id}")

    assert html =~ "Already Paid"
  end

  test "handles payment_processing event", %{conn: conn, job: job} do
    {:ok, view, _html} = live(conn, "/pay/#{job.id}")

    render_hook(view, "payment_processing", %{})

    html = render(view)
    assert html =~ "Processing Payment"
  end
end
