defmodule Haul.Notifications.BookingEmailTest do
  use ExUnit.Case, async: true

  alias Haul.Notifications.BookingEmail

  @job %{
    customer_name: "Jane Doe",
    customer_phone: "(555) 987-6543",
    customer_email: "jane@example.com",
    address: "123 Main St, Anytown, USA",
    item_description: "Old couch and two mattresses",
    notes: "Back door entrance",
    preferred_dates: [],
    photo_urls: []
  }

  describe "operator_alert/1" do
    test "builds email with correct subject and recipients" do
      email = BookingEmail.operator_alert(@job)
      operator = Application.get_env(:haul, :operator, [])

      assert email.subject == "New booking from Jane Doe"
      assert [{operator[:business_name], operator[:email]}] == email.to
      assert {operator[:business_name], operator[:email]} == email.from
    end

    test "text_body contains all customer fields" do
      email = BookingEmail.operator_alert(@job)

      assert email.text_body =~ "Jane Doe"
      assert email.text_body =~ "(555) 987-6543"
      assert email.text_body =~ "jane@example.com"
      assert email.text_body =~ "123 Main St, Anytown, USA"
      assert email.text_body =~ "Old couch and two mattresses"
      assert email.text_body =~ "Back door entrance"
    end

    test "html_body contains all customer fields" do
      email = BookingEmail.operator_alert(@job)

      assert email.html_body =~ "Jane Doe"
      assert email.html_body =~ "(555) 987-6543"
      assert email.html_body =~ "jane@example.com"
      assert email.html_body =~ "123 Main St, Anytown, USA"
      assert email.html_body =~ "Old couch and two mattresses"
      assert email.html_body =~ "Back door entrance"
    end

    test "html_body contains HTML structure" do
      email = BookingEmail.operator_alert(@job)

      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "<table"
      assert email.html_body =~ "New Booking Request"
    end

    test "shows 'not provided' when customer_email is nil" do
      job = %{@job | customer_email: nil}
      email = BookingEmail.operator_alert(job)

      assert email.text_body =~ "not provided"
      assert email.html_body =~ "not provided"
    end

    test "shows 'none' when notes are nil" do
      job = %{@job | notes: nil}
      email = BookingEmail.operator_alert(job)

      assert email.text_body =~ "none"
    end

    test "operator branding in html header and footer" do
      email = BookingEmail.operator_alert(@job)
      operator = Application.get_env(:haul, :operator, [])

      # Business name appears (HTML-escaped) in header and footer
      escaped_name = operator[:business_name] |> String.replace("&", "&amp;")
      assert email.html_body =~ escaped_name
      assert email.html_body =~ operator[:phone]
    end
  end

  describe "customer_confirmation/1" do
    test "builds email with correct subject and recipients" do
      email = BookingEmail.customer_confirmation(@job)
      operator = Application.get_env(:haul, :operator, [])

      assert email.subject == "Booking received — #{operator[:business_name]}"
      assert [{"", "jane@example.com"}] == email.to
      assert {operator[:business_name], operator[:email]} == email.from
    end

    test "text_body contains summary and contact info" do
      email = BookingEmail.customer_confirmation(@job)
      operator = Application.get_env(:haul, :operator, [])

      assert email.text_body =~ "Hi Jane Doe"
      assert email.text_body =~ "123 Main St, Anytown, USA"
      assert email.text_body =~ "Old couch and two mattresses"
      assert email.text_body =~ "(555) 987-6543"
      assert email.text_body =~ operator[:business_name]
      assert email.text_body =~ operator[:phone]
    end

    test "html_body contains summary and contact info" do
      email = BookingEmail.customer_confirmation(@job)

      assert email.html_body =~ "Jane Doe"
      assert email.html_body =~ "123 Main St, Anytown, USA"
      assert email.html_body =~ "Old couch and two mattresses"
      assert email.html_body =~ "(555) 987-6543"
    end

    test "html_body contains HTML structure" do
      email = BookingEmail.customer_confirmation(@job)

      assert email.html_body =~ "<!DOCTYPE html>"
      assert email.html_body =~ "We received your request"
    end
  end
end
