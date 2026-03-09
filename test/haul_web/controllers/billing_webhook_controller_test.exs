defmodule HaulWeb.BillingWebhookControllerTest do
  use HaulWeb.ConnCase, async: false

  alias Haul.Accounts.Company

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Webhook Test Co",
        slug: "webhook-test-co"
      })
      |> Ash.create()

    # Set up billing fields
    {:ok, company} =
      company
      |> Ash.Changeset.for_update(:update_company, %{
        stripe_customer_id: "cus_test_123",
        stripe_subscription_id: "sub_test_456",
        subscription_plan: :pro
      })
      |> Ash.update()

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

    %{company: company}
  end

  defp billing_webhook_payload(type, object) do
    Jason.encode!(%{
      "id" => "evt_test_#{System.unique_integer([:positive])}",
      "type" => type,
      "data" => %{"object" => object}
    })
  end

  defp post_billing_webhook(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("stripe-signature", "test_sig")
    |> post("/webhooks/stripe/billing", payload)
  end

  describe "POST /webhooks/stripe/billing — checkout.session.completed" do
    test "sets plan and stores stripe IDs", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("checkout.session.completed", %{
          "id" => "cs_test_789",
          "customer" => "cus_test_123",
          "subscription" => "sub_new_789",
          "metadata" => %{
            "company_id" => company.id,
            "plan" => "business"
          }
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.subscription_plan == :business
      assert updated.stripe_subscription_id == "sub_new_789"
      assert updated.stripe_customer_id == "cus_test_123"
    end

    test "is idempotent", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("checkout.session.completed", %{
          "id" => "cs_test_idem",
          "customer" => "cus_test_123",
          "subscription" => "sub_idem",
          "metadata" => %{
            "company_id" => company.id,
            "plan" => "business"
          }
        })

      resp1 = post_billing_webhook(conn, payload)
      assert json_response(resp1, 200) == %{"status" => "ok"}

      resp2 = post_billing_webhook(conn, payload)
      assert json_response(resp2, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.subscription_plan == :business
    end
  end

  describe "POST /webhooks/stripe/billing — customer.subscription.updated" do
    test "updates plan tier based on price ID", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("customer.subscription.updated", %{
          "id" => "sub_test_456",
          "customer" => "cus_test_123",
          "status" => "active",
          "items" => %{
            "data" => [
              %{"price" => %{"id" => "price_test_business"}}
            ]
          }
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.subscription_plan == :business
    end

    test "no-ops when plan unchanged", %{conn: conn} do
      payload =
        billing_webhook_payload("customer.subscription.updated", %{
          "id" => "sub_test_456",
          "customer" => "cus_test_123",
          "status" => "active",
          "items" => %{
            "data" => [
              %{"price" => %{"id" => "price_test_pro"}}
            ]
          }
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}
    end
  end

  describe "POST /webhooks/stripe/billing — customer.subscription.deleted" do
    test "downgrades to starter", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("customer.subscription.deleted", %{
          "id" => "sub_test_456",
          "customer" => "cus_test_123"
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.subscription_plan == :starter
      assert is_nil(updated.stripe_subscription_id)
    end

    test "is idempotent — already starter", %{conn: conn, company: company} do
      # First downgrade
      payload =
        billing_webhook_payload("customer.subscription.deleted", %{
          "id" => "sub_test_456",
          "customer" => "cus_test_123"
        })

      post_billing_webhook(conn, payload)

      # Second downgrade
      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.subscription_plan == :starter
    end
  end

  describe "POST /webhooks/stripe/billing — invoice.payment_failed" do
    test "sets dunning_started_at after final retry", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("invoice.payment_failed", %{
          "id" => "in_test_fail",
          "customer" => "cus_test_123",
          "subscription" => "sub_test_456",
          "attempt_count" => 3
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert not is_nil(updated.dunning_started_at)
    end

    test "does not set dunning for early retries", %{conn: conn, company: company} do
      payload =
        billing_webhook_payload("invoice.payment_failed", %{
          "id" => "in_test_early",
          "customer" => "cus_test_123",
          "subscription" => "sub_test_456",
          "attempt_count" => 1
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert is_nil(updated.dunning_started_at)
    end

    test "is idempotent — doesn't reset dunning_started_at", %{conn: conn, company: company} do
      # Set dunning manually to a known time
      past = ~U[2026-03-01 00:00:00Z]

      {:ok, _} =
        company
        |> Ash.Changeset.for_update(:update_company, %{dunning_started_at: past})
        |> Ash.update()

      payload =
        billing_webhook_payload("invoice.payment_failed", %{
          "id" => "in_test_idem",
          "customer" => "cus_test_123",
          "subscription" => "sub_test_456",
          "attempt_count" => 3
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      # Should not have been reset — idempotent
      assert updated.dunning_started_at == past
    end
  end

  describe "POST /webhooks/stripe/billing — invoice.paid" do
    test "clears dunning state", %{conn: conn, company: company} do
      # Set dunning first
      {:ok, _} =
        company
        |> Ash.Changeset.for_update(:update_company, %{dunning_started_at: DateTime.utc_now()})
        |> Ash.update()

      payload =
        billing_webhook_payload("invoice.paid", %{
          "id" => "in_test_paid",
          "customer" => "cus_test_123",
          "subscription" => "sub_test_456"
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated} = Ash.get(Company, company.id)
      assert is_nil(updated.dunning_started_at)
    end

    test "no-ops when no dunning state", %{conn: conn} do
      payload =
        billing_webhook_payload("invoice.paid", %{
          "id" => "in_test_paid2",
          "customer" => "cus_test_123",
          "subscription" => "sub_test_456"
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}
    end
  end

  describe "POST /webhooks/stripe/billing — edge cases" do
    test "unknown event type returns 200", %{conn: conn} do
      payload =
        billing_webhook_payload("charge.refunded", %{"id" => "ch_test"})

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}
    end

    test "unknown customer returns 200", %{conn: conn} do
      payload =
        billing_webhook_payload("customer.subscription.deleted", %{
          "id" => "sub_unknown",
          "customer" => "cus_nonexistent"
        })

      resp = post_billing_webhook(conn, payload)
      assert json_response(resp, 200) == %{"status" => "ok"}
    end

    test "invalid payload returns 400", %{conn: conn} do
      resp =
        conn
        |> put_req_header("content-type", "text/plain")
        |> put_req_header("stripe-signature", "test_sig")
        |> post("/webhooks/stripe/billing", "not valid json")

      assert json_response(resp, 400) == %{"error" => "invalid_signature"}
    end
  end
end
