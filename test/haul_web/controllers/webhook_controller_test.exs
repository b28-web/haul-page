defmodule HaulWeb.WebhookControllerTest do
  use HaulWeb.ConnCase, async: false

  alias Haul.Operations.Job

  setup do
    %{tenant: tenant} = create_operator_context()

    {:ok, job} =
      Job
      |> Ash.Changeset.for_create(:create_from_online_booking, %{
        customer_name: "Jane Doe",
        customer_phone: "(555) 123-4567",
        customer_email: "jane@example.com",
        address: "123 Main St",
        item_description: "Old couch"
      })
      |> Ash.create(tenant: tenant)

    %{tenant: tenant, job: job}
  end

  defp webhook_payload(type, intent_id, metadata) do
    Jason.encode!(%{
      "id" => "evt_test_#{System.unique_integer([:positive])}",
      "type" => type,
      "data" => %{
        "object" => %{
          "id" => intent_id,
          "object" => "payment_intent",
          "metadata" => metadata
        }
      }
    })
  end

  defp post_webhook(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("stripe-signature", "test_sig")
    |> post("/webhooks/stripe", payload)
  end

  describe "POST /webhooks/stripe" do
    test "payment_intent.succeeded updates job payment_intent_id", %{
      conn: conn,
      job: job,
      tenant: tenant
    } do
      payload =
        webhook_payload("payment_intent.succeeded", "pi_webhook_123", %{
          "job_id" => job.id,
          "tenant" => tenant
        })

      resp = post_webhook(conn, payload)

      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, updated_job} = Ash.get(Job, job.id, tenant: tenant)
      assert updated_job.payment_intent_id == "pi_webhook_123"
    end

    test "payment_intent.succeeded is idempotent", %{conn: conn, job: job, tenant: tenant} do
      payload =
        webhook_payload("payment_intent.succeeded", "pi_webhook_456", %{
          "job_id" => job.id,
          "tenant" => tenant
        })

      resp1 = post_webhook(conn, payload)
      assert json_response(resp1, 200) == %{"status" => "ok"}

      resp2 = post_webhook(conn, payload)
      assert json_response(resp2, 200) == %{"status" => "ok"}

      {:ok, updated_job} = Ash.get(Job, job.id, tenant: tenant)
      assert updated_job.payment_intent_id == "pi_webhook_456"
    end

    test "payment_intent.payment_failed returns 200", %{conn: conn, job: job, tenant: tenant} do
      payload =
        webhook_payload("payment_intent.payment_failed", "pi_failed_123", %{
          "job_id" => job.id,
          "tenant" => tenant
        })

      resp = post_webhook(conn, payload)

      assert json_response(resp, 200) == %{"status" => "ok"}

      {:ok, unchanged_job} = Ash.get(Job, job.id, tenant: tenant)
      assert is_nil(unchanged_job.payment_intent_id)
    end

    test "unknown event type returns 200", %{conn: conn} do
      payload =
        webhook_payload("charge.refunded", "ch_123", %{})

      resp = post_webhook(conn, payload)

      assert json_response(resp, 200) == %{"status" => "ok"}
    end

    test "missing metadata returns 200", %{conn: conn} do
      payload =
        webhook_payload("payment_intent.succeeded", "pi_no_meta", %{})

      resp = post_webhook(conn, payload)

      assert json_response(resp, 200) == %{"status" => "ok"}
    end

    test "invalid payload returns 400", %{conn: conn} do
      # Send a request with content-type text/plain so Plug.Parsers passes through
      # without attempting JSON decode. The raw body "not valid json" reaches the
      # controller and the sandbox adapter's verify_webhook_signature rejects it.
      resp =
        conn
        |> put_req_header("content-type", "text/plain")
        |> put_req_header("stripe-signature", "test_sig")
        |> post("/webhooks/stripe", "not valid json")

      assert json_response(resp, 400) == %{"error" => "invalid_signature"}
    end
  end
end
