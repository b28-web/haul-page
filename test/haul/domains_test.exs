defmodule Haul.DomainsTest do
  use ExUnit.Case, async: true

  alias Haul.Domains

  describe "normalize_domain/1" do
    test "strips https:// prefix" do
      assert Domains.normalize_domain("https://www.example.com") == "www.example.com"
    end

    test "strips http:// prefix" do
      assert Domains.normalize_domain("http://example.com") == "example.com"
    end

    test "strips trailing path" do
      assert Domains.normalize_domain("www.example.com/path/to/page") == "www.example.com"
    end

    test "downcases domain" do
      assert Domains.normalize_domain("WWW.EXAMPLE.COM") == "www.example.com"
    end

    test "strips whitespace" do
      assert Domains.normalize_domain("  example.com  ") == "example.com"
    end

    test "handles combined normalization" do
      assert Domains.normalize_domain("  HTTPS://Www.Example.Com/path  ") == "www.example.com"
    end

    test "passes through clean domain unchanged" do
      assert Domains.normalize_domain("www.example.com") == "www.example.com"
    end

    test "returns empty string for nil" do
      assert Domains.normalize_domain(nil) == ""
    end
  end

  describe "valid_domain?/1" do
    test "accepts valid domains" do
      assert Domains.valid_domain?("www.example.com")
      assert Domains.valid_domain?("example.com")
      assert Domains.valid_domain?("sub.domain.example.com")
      assert Domains.valid_domain?("my-site.example.com")
    end

    test "rejects domains without a dot" do
      refute Domains.valid_domain?("localhost")
      refute Domains.valid_domain?("example")
    end

    test "rejects domains starting with hyphen" do
      refute Domains.valid_domain?("-example.com")
    end

    test "rejects domains ending with hyphen" do
      refute Domains.valid_domain?("example-.com")
    end

    test "rejects domains with spaces" do
      refute Domains.valid_domain?("example .com")
    end

    test "rejects empty string" do
      refute Domains.valid_domain?("")
    end

    test "rejects nil" do
      refute Domains.valid_domain?(nil)
    end
  end
end
