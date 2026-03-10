defmodule Haul.OnboardingUnitTest do
  use ExUnit.Case, async: true

  describe "derive_slug/1" do
    test "lowercases and hyphenates" do
      assert Haul.Onboarding.derive_slug("Joe's Hauling") == "joe-s-hauling"
    end

    test "handles special characters" do
      assert Haul.Onboarding.derive_slug("A & B Junk Co.") == "a-b-junk-co"
    end

    test "trims leading/trailing hyphens" do
      assert Haul.Onboarding.derive_slug("  Test Co  ") == "test-co"
    end

    test "collapses multiple separators" do
      assert Haul.Onboarding.derive_slug("foo---bar") == "foo-bar"
    end
  end

  describe "site_url/1" do
    test "constructs URL with base domain" do
      url = Haul.Onboarding.site_url("test-co")
      assert url =~ "test-co."
      assert url =~ "https://"
    end
  end
end
