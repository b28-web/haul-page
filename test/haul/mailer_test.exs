defmodule Haul.MailerTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  describe "test_email/1" do
    test "delivers a test email to the given address" do
      assert {:ok, _} = Haul.Mailer.test_email("user@example.com")

      assert_email_sent(fn email ->
        assert email.to == [{"", "user@example.com"}]
        assert email.subject =~ "Test email"
        assert email.text_body =~ "configured correctly"
      end)
    end

    test "uses operator config for sender" do
      assert {:ok, _} = Haul.Mailer.test_email("user@example.com")

      assert_email_sent(fn email ->
        {from_name, _from_email} = email.from
        operator = Application.get_env(:haul, :operator, [])
        expected_name = Keyword.get(operator, :business_name, "Haul")
        assert from_name == expected_name
      end)
    end
  end
end
