defmodule Haul.SentryConfigTest do
  use ExUnit.Case, async: true

  describe "Sentry configuration" do
    test "DSN is not set in test environment" do
      refute Application.get_env(:sentry, :dsn)
    end

    test "environment_name is :test" do
      assert Application.get_env(:sentry, :environment_name) == :test
    end

    test "source code context is enabled" do
      assert Application.get_env(:sentry, :enable_source_code_context) == true
    end
  end
end
