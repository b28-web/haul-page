defmodule Haul.PaymentsTest do
  use ExUnit.Case, async: true

  alias Haul.Payments

  describe "create_payment_intent/1" do
    test "returns a payment intent with required fields" do
      Process.put(:payments_sandbox_pid, self())

      params = %{amount: 5000, currency: "usd"}
      assert {:ok, intent} = Payments.create_payment_intent(params)

      assert intent.amount == 5000
      assert intent.currency == "usd"
      assert intent.status == "requires_payment_method"
      assert String.starts_with?(intent.id, "pi_sandbox_")
      assert String.starts_with?(intent.client_secret, "pi_sandbox_secret_")
      assert intent.metadata == %{}

      assert_received {:payment_intent_created, ^intent}
    end

    test "includes metadata when provided" do
      params = %{amount: 10_000, currency: "usd", metadata: %{"job_id" => "abc123"}}
      assert {:ok, intent} = Payments.create_payment_intent(params)

      assert intent.metadata == %{"job_id" => "abc123"}
    end

    test "returns error when required params are missing" do
      assert {:error, :missing_required_params} = Payments.create_payment_intent(%{})
      assert {:error, :missing_required_params} = Payments.create_payment_intent(%{amount: 5000})

      assert {:error, :missing_required_params} =
               Payments.create_payment_intent(%{currency: "usd"})
    end
  end

  describe "retrieve_payment_intent/1" do
    test "returns a succeeded payment intent" do
      Process.put(:payments_sandbox_pid, self())

      assert {:ok, intent} = Payments.retrieve_payment_intent("pi_test_123")

      assert intent.id == "pi_test_123"
      assert intent.status == "succeeded"
      assert intent.object == "payment_intent"

      assert_received {:payment_intent_retrieved, ^intent}
    end
  end

  describe "verify_webhook_signature/3" do
    test "returns decoded event for valid JSON payload" do
      payload = Jason.encode!(%{"type" => "payment_intent.succeeded", "data" => %{}})

      assert {:ok, event} = Payments.verify_webhook_signature(payload, "sig", "secret")
      assert event["type"] == "payment_intent.succeeded"
    end

    test "returns error for invalid payload" do
      assert {:error, :invalid_payload} =
               Payments.verify_webhook_signature("not json", "sig", "secret")
    end
  end
end
