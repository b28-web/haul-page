defmodule Haul.AI.OnboardingPromptTest do
  use ExUnit.Case, async: true

  alias Haul.AI.Prompt

  setup do
    {:ok, content} = Prompt.load("onboarding_agent")
    %{content: content}
  end

  describe "required fields" do
    test "mentions business_name", %{content: content} do
      assert content =~ "business_name"
    end

    test "mentions phone", %{content: content} do
      assert content =~ "phone"
    end

    test "mentions email", %{content: content} do
      assert content =~ "email"
    end
  end

  describe "service categories" do
    test "mentions junk removal", %{content: content} do
      assert content =~ "junk removal"
    end

    test "mentions cleanouts", %{content: content} do
      assert content =~ "cleanouts"
    end

    test "mentions yard waste", %{content: content} do
      assert content =~ "yard waste"
    end
  end

  describe "conversation design" do
    test "has an opening message", %{content: content} do
      assert content =~ "What's the name of your business?"
    end

    test "has a wrap-up transition", %{content: content} do
      assert content =~ "Ready to see it come together?"
    end

    test "has tone guidelines", %{content: content} do
      assert content =~ "2-3 sentences"
    end

    test "handles off-topic redirection", %{content: content} do
      assert content =~ "Off-topic"
    end

    test "handles pricing questions", %{content: content} do
      assert content =~ "pricing"
    end

    test "handles terse answers", %{content: content} do
      assert content =~ "Terse"
    end

    test "handles chatty users", %{content: content} do
      assert content =~ "Chatty"
    end

    test "handles non-English speakers", %{content: content} do
      assert content =~ "Non-English"
    end
  end

  describe "version" do
    test "is v1" do
      assert {:ok, "v1"} = Prompt.version("onboarding_agent")
    end
  end
end
