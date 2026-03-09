defmodule Haul.ConfigTest do
  use ExUnit.Case, async: true

  describe "operator config" do
    test "has all required keys" do
      operator = Application.get_env(:haul, :operator)
      assert is_list(operator)

      for key <- [
            :business_name,
            :phone,
            :email,
            :tagline,
            :service_area,
            :coupon_text,
            :services
          ] do
        assert Keyword.has_key?(operator, key), "missing operator config key: #{key}"
      end
    end

    test "string fields are non-empty" do
      operator = Application.get_env(:haul, :operator)

      for key <- [:business_name, :phone, :email] do
        value = Keyword.fetch!(operator, key)
        assert is_binary(value) and value != "", "#{key} should be a non-empty string"
      end
    end

    test "services list has expected structure" do
      services = Application.get_env(:haul, :operator)[:services]
      assert is_list(services)
      assert services != []

      for service <- services do
        assert is_map(service)
        assert Map.has_key?(service, :title)
        assert Map.has_key?(service, :description)
        assert Map.has_key?(service, :icon)
      end
    end
  end
end
