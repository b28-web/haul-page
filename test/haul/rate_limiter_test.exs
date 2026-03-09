defmodule Haul.RateLimiterTest do
  use ExUnit.Case, async: true

  alias Haul.RateLimiter

  describe "check_rate/3" do
    test "allows requests under the limit" do
      key = {:test, make_ref()}

      assert :ok = RateLimiter.check_rate(key, 3, 60)
      assert :ok = RateLimiter.check_rate(key, 3, 60)
      assert :ok = RateLimiter.check_rate(key, 3, 60)
    end

    test "blocks requests over the limit" do
      key = {:test, make_ref()}

      assert :ok = RateLimiter.check_rate(key, 2, 60)
      assert :ok = RateLimiter.check_rate(key, 2, 60)
      assert {:error, :rate_limited} = RateLimiter.check_rate(key, 2, 60)
    end

    test "different keys are independent" do
      key1 = {:test, make_ref()}
      key2 = {:test, make_ref()}

      assert :ok = RateLimiter.check_rate(key1, 1, 60)
      assert {:error, :rate_limited} = RateLimiter.check_rate(key1, 1, 60)
      assert :ok = RateLimiter.check_rate(key2, 1, 60)
    end

    test "window separates old from new requests" do
      key = {:test, make_ref()}

      # Fill with limit=2 in a 60s window
      assert :ok = RateLimiter.check_rate(key, 2, 60)
      assert :ok = RateLimiter.check_rate(key, 2, 60)
      assert {:error, :rate_limited} = RateLimiter.check_rate(key, 2, 60)

      # But with a fresh key, still works
      key2 = {:test, make_ref()}
      assert :ok = RateLimiter.check_rate(key2, 2, 60)
    end
  end
end
