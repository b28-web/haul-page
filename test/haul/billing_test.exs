defmodule Haul.BillingTest do
  use ExUnit.Case, async: true

  alias Haul.Billing

  describe "can?/2" do
    test "starter plan has no features" do
      company = %{subscription_plan: :starter}
      refute Billing.can?(company, :sms_notifications)
      refute Billing.can?(company, :custom_domain)
      refute Billing.can?(company, :payment_collection)
      refute Billing.can?(company, :crew_app)
    end

    test "pro plan includes sms_notifications and custom_domain" do
      company = %{subscription_plan: :pro}
      assert Billing.can?(company, :sms_notifications)
      assert Billing.can?(company, :custom_domain)
      refute Billing.can?(company, :payment_collection)
      refute Billing.can?(company, :crew_app)
    end

    test "business plan includes all features" do
      company = %{subscription_plan: :business}
      assert Billing.can?(company, :sms_notifications)
      assert Billing.can?(company, :custom_domain)
      assert Billing.can?(company, :payment_collection)
      assert Billing.can?(company, :crew_app)
    end

    test "dedicated plan includes all features" do
      company = %{subscription_plan: :dedicated}
      assert Billing.can?(company, :sms_notifications)
      assert Billing.can?(company, :custom_domain)
      assert Billing.can?(company, :payment_collection)
      assert Billing.can?(company, :crew_app)
    end

    test "returns false for unknown feature" do
      company = %{subscription_plan: :dedicated}
      refute Billing.can?(company, :nonexistent_feature)
    end

    test "returns false for nil company" do
      refute Billing.can?(nil, :sms_notifications)
    end
  end

  describe "plan_features/1" do
    test "starter has empty feature list" do
      assert Billing.plan_features(:starter) == []
    end

    test "pro includes sms_notifications and custom_domain" do
      features = Billing.plan_features(:pro)
      assert :sms_notifications in features
      assert :custom_domain in features
      assert length(features) == 2
    end

    test "business includes all four features" do
      features = Billing.plan_features(:business)
      assert :sms_notifications in features
      assert :custom_domain in features
      assert :payment_collection in features
      assert :crew_app in features
      assert length(features) == 4
    end

    test "dedicated matches business features" do
      assert Billing.plan_features(:dedicated) == Billing.plan_features(:business)
    end

    test "unknown plan returns empty list" do
      assert Billing.plan_features(:unknown) == []
    end
  end

  describe "plans/0" do
    test "returns four plans" do
      plans = Billing.plans()
      assert length(plans) == 4
    end

    test "plans have correct structure" do
      for plan <- Billing.plans() do
        assert Map.has_key?(plan, :id)
        assert Map.has_key?(plan, :name)
        assert Map.has_key?(plan, :price_cents)
        assert Map.has_key?(plan, :features)
        assert is_atom(plan.id)
        assert is_binary(plan.name)
        assert is_integer(plan.price_cents)
        assert is_list(plan.features)
      end
    end

    test "starter is free" do
      starter = Billing.plans() |> Enum.find(&(&1.id == :starter))
      assert starter.price_cents == 0
    end

    test "pro is $29/mo" do
      pro = Billing.plans() |> Enum.find(&(&1.id == :pro))
      assert pro.price_cents == 2900
    end

    test "business is $79/mo" do
      biz = Billing.plans() |> Enum.find(&(&1.id == :business))
      assert biz.price_cents == 7900
    end

    test "dedicated is $149/mo" do
      ded = Billing.plans() |> Enum.find(&(&1.id == :dedicated))
      assert ded.price_cents == 14_900
    end
  end

  describe "create_customer/1 (sandbox)" do
    test "returns customer ID" do
      Process.put(:billing_sandbox_pid, self())
      company = %{id: "test-id", name: "Test Co"}

      assert {:ok, customer_id} = Billing.create_customer(company)
      assert String.starts_with?(customer_id, "cus_sandbox_")
      assert_received {:customer_created, ^customer_id, ^company}
    end
  end

  describe "create_subscription/2 (sandbox)" do
    test "returns subscription map" do
      Process.put(:billing_sandbox_pid, self())

      assert {:ok, sub} = Billing.create_subscription("cus_123", "price_pro")
      assert String.starts_with?(sub.id, "sub_sandbox_")
      assert sub.status == "active"
      assert sub.customer == "cus_123"
      assert_received {:subscription_created, ^sub, "price_pro"}
    end
  end

  describe "cancel_subscription/1 (sandbox)" do
    test "returns canceled subscription" do
      Process.put(:billing_sandbox_pid, self())

      assert {:ok, sub} = Billing.cancel_subscription("sub_existing_123")
      assert sub.id == "sub_existing_123"
      assert sub.status == "canceled"
      assert_received {:subscription_canceled, ^sub}
    end
  end

  describe "create_checkout_session/1 (sandbox)" do
    test "returns session with URL" do
      Process.put(:billing_sandbox_pid, self())

      params = %{
        customer_id: "cus_123",
        price_id: "price_pro",
        success_url: "http://localhost/billing",
        cancel_url: "http://localhost/billing"
      }

      assert {:ok, session} = Billing.create_checkout_session(params)
      assert String.starts_with?(session.id, "cs_sandbox_")
      assert session.url =~ "session_id=cs_sandbox_"
      assert_received {:checkout_session_created, ^session, ^params}
    end
  end

  describe "create_portal_session/2 (sandbox)" do
    test "returns portal URL" do
      Process.put(:billing_sandbox_pid, self())

      assert {:ok, %{url: url}} =
               Billing.create_portal_session("cus_123", "http://localhost/billing")

      assert url == "http://localhost/billing"
      assert_received {:portal_session_created, _, "cus_123"}
    end
  end

  describe "update_subscription/2 (sandbox)" do
    test "returns updated subscription" do
      Process.put(:billing_sandbox_pid, self())

      params = %{price_id: "price_business"}
      assert {:ok, sub} = Billing.update_subscription("sub_123", params)
      assert sub.id == "sub_123"
      assert sub.status == "active"
      assert_received {:subscription_updated, ^sub, ^params}
    end
  end

  describe "feature_label/1" do
    test "returns human-readable labels" do
      assert Billing.feature_label(:sms_notifications) == "SMS Notifications"
      assert Billing.feature_label(:custom_domain) == "Custom Domain"
      assert Billing.feature_label(:payment_collection) == "Payment Collection"
      assert Billing.feature_label(:crew_app) == "Crew App"
    end

    test "falls back to string for unknown feature" do
      assert Billing.feature_label(:unknown) == "unknown"
    end
  end

  describe "price_id/1" do
    test "returns configured price for paid plans" do
      # In test config, these are empty strings
      assert is_binary(Billing.price_id(:pro))
      assert is_binary(Billing.price_id(:business))
      assert is_binary(Billing.price_id(:dedicated))
    end

    test "returns nil for starter" do
      assert Billing.price_id(:starter) == nil
    end
  end

  describe "plan_for_price_id/1" do
    test "maps configured price IDs back to plan atoms" do
      assert Billing.plan_for_price_id("price_test_pro") == :pro
      assert Billing.plan_for_price_id("price_test_business") == :business
      assert Billing.plan_for_price_id("price_test_dedicated") == :dedicated
    end

    test "returns nil for unknown price ID" do
      assert Billing.plan_for_price_id("price_unknown") == nil
    end

    test "returns nil for non-string input" do
      assert Billing.plan_for_price_id(nil) == nil
      assert Billing.plan_for_price_id(123) == nil
    end
  end
end
