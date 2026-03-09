defmodule Haul.Notifications.BookingSMSTest do
  use ExUnit.Case, async: true

  alias Haul.Notifications.BookingSMS

  @job %{
    customer_name: "Jane Doe",
    customer_phone: "(555) 987-6543",
    address: "123 Main St, Anytown, USA"
  }

  describe "operator_alert/1" do
    test "contains customer name, phone, and address" do
      msg = BookingSMS.operator_alert(@job)

      assert msg =~ "Jane Doe"
      assert msg =~ "(555) 987-6543"
      assert msg =~ "123 Main St"
    end

    test "is under 160 characters for typical input" do
      msg = BookingSMS.operator_alert(@job)

      assert String.length(msg) <= 160
    end

    test "format matches expected pattern" do
      msg = BookingSMS.operator_alert(@job)

      assert msg == "New booking from Jane Doe — (555) 987-6543. 123 Main St, Anytown, USA"
    end
  end
end
