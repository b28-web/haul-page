defmodule Haul.AI.EditClassifierTest do
  use ExUnit.Case, async: true

  alias Haul.AI.EditClassifier

  describe "classify/1 direct updates" do
    test "classifies phone number change" do
      assert {:direct, :phone, "555-9999"} =
               EditClassifier.classify("The phone number should be 555-9999")
    end

    test "classifies phone with parentheses" do
      assert {:direct, :phone, "(555) 123-4567"} =
               EditClassifier.classify("Change phone to (555) 123-4567")
    end

    test "classifies email change" do
      assert {:direct, :email, "new@example.com"} =
               EditClassifier.classify("Change email to new@example.com")
    end

    test "classifies email with plus addressing" do
      assert {:direct, :email, "user+tag@example.com"} =
               EditClassifier.classify("Email should be user+tag@example.com")
    end

    test "classifies business name change" do
      assert {:direct, :business_name, "Haulers Inc"} =
               EditClassifier.classify("Business name should be Haulers Inc")
    end

    test "classifies company name change" do
      assert {:direct, :business_name, "New Co"} =
               EditClassifier.classify("Company name is New Co")
    end

    test "classifies owner name change" do
      assert {:direct, :owner_name, "John Smith"} =
               EditClassifier.classify("Owner name should be John Smith")
    end

    test "classifies my name" do
      assert {:direct, :owner_name, "Jane Doe"} =
               EditClassifier.classify("My name is Jane Doe")
    end

    test "classifies service area change" do
      assert {:direct, :service_area, "Greater Portland"} =
               EditClassifier.classify("Service area should be Greater Portland")
    end

    test "classifies area change" do
      assert {:direct, :service_area, "Seattle Metro"} =
               EditClassifier.classify("Area is Seattle Metro")
    end
  end

  describe "classify/1 service management" do
    test "classifies remove service" do
      assert {:remove_service, "Assembly"} =
               EditClassifier.classify("Remove the Assembly service")
    end

    test "classifies remove without 'the'" do
      assert {:remove_service, "Yard Waste"} =
               EditClassifier.classify("Remove Yard Waste")
    end

    test "classifies add service" do
      assert {:add_service, "Demolition"} =
               EditClassifier.classify("Add a Demolition service")
    end

    test "classifies add without article" do
      assert {:add_service, "Moving Help"} =
               EditClassifier.classify("Add Moving Help")
    end
  end

  describe "classify/1 regeneration" do
    test "classifies tagline change" do
      assert {:regenerate, :tagline, _} =
               EditClassifier.classify("Change the tagline to something about same-day service")
    end

    test "classifies slogan" do
      assert {:regenerate, :tagline, _} =
               EditClassifier.classify("Make the slogan more catchy")
    end

    test "classifies description change" do
      assert {:regenerate, :descriptions, _} =
               EditClassifier.classify("Rewrite the junk removal description")
    end

    test "classifies describe request" do
      assert {:regenerate, :descriptions, _} =
               EditClassifier.classify("Make the description more professional")
    end
  end

  describe "classify/1 unknown" do
    test "returns unknown for unrecognized messages" do
      assert {:unknown, "I like the color blue"} =
               EditClassifier.classify("I like the color blue")
    end

    test "returns unknown for empty-ish messages" do
      assert {:unknown, "hmm"} = EditClassifier.classify("hmm")
    end

    test "trims whitespace" do
      assert {:unknown, "hello"} = EditClassifier.classify("  hello  ")
    end
  end
end
