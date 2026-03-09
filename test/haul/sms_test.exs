defmodule Haul.SMSTest do
  use ExUnit.Case, async: true

  describe "send_sms/3 via Sandbox adapter" do
    test "delivers message and notifies calling process" do
      assert {:ok, result} = Haul.SMS.send_sms("+15551234567", "Your booking is confirmed.")

      assert result.to == "+15551234567"
      assert result.body == "Your booking is confirmed."
      assert result.status == "sent"
      assert String.starts_with?(result.sid, "sandbox-")
    end

    test "sends {:sms_sent, message} to the calling process" do
      {:ok, _} = Haul.SMS.send_sms("+15559876543", "Test message")

      assert_received {:sms_sent, message}
      assert message.to == "+15559876543"
      assert message.body == "Test message"
    end

    test "accepts :from option override" do
      {:ok, result} = Haul.SMS.send_sms("+15551111111", "Hello", from: "+15550000000")

      assert result.from == "+15550000000"
    end

    test "defaults from to sandbox when no option given" do
      {:ok, result} = Haul.SMS.send_sms("+15551111111", "Hello")

      assert result.from == "sandbox"
    end
  end
end
