defmodule Haul.Notifications.BookingEmail do
  @moduledoc """
  Builds Swoosh email structs for booking notifications.

  Two templates:
  - `operator_alert/1` — notifies the operator of a new booking
  - `customer_confirmation/1` — confirms receipt to the customer
  """

  import Swoosh.Email

  @doc """
  Builds an operator alert email for a new booking.
  Includes customer name, phone, email, address, item description, and notes.
  """
  def operator_alert(job) do
    operator = operator_config()

    new()
    |> to({operator[:business_name], operator[:email]})
    |> from({operator[:business_name], operator[:email]})
    |> subject("New booking from #{job.customer_name}")
    |> text_body(operator_alert_text(job, operator))
    |> html_body(operator_alert_html(job, operator))
  end

  @doc """
  Builds a customer confirmation email for a new booking.
  Summarizes the submitted info and lets them know the operator will be in touch.
  """
  def customer_confirmation(job) do
    operator = operator_config()

    new()
    |> to(job.customer_email)
    |> from({operator[:business_name], operator[:email]})
    |> subject("Booking received — #{operator[:business_name]}")
    |> text_body(customer_confirmation_text(job, operator))
    |> html_body(customer_confirmation_html(job, operator))
  end

  defp operator_config do
    Application.get_env(:haul, :operator, [])
  end

  # -- Plain text bodies --

  defp operator_alert_text(job, _operator) do
    """
    New booking request received:

    Customer: #{job.customer_name}
    Phone: #{job.customer_phone}
    Email: #{job.customer_email || "not provided"}
    Address: #{job.address}

    Items: #{job.item_description}

    Notes: #{job.notes || "none"}
    """
  end

  defp customer_confirmation_text(job, operator) do
    """
    Hi #{job.customer_name},

    We received your booking request. Here's a summary:

    Pickup address: #{job.address}
    Items: #{job.item_description}

    We'll contact you shortly at #{job.customer_phone} to confirm your pickup.

    Thanks,
    #{operator[:business_name]}
    #{operator[:phone]}
    """
  end

  # -- HTML bodies --

  defp operator_alert_html(job, operator) do
    content = """
    <h2 style="margin:0 0 16px 0;font-size:20px;color:#111;">New Booking Request</h2>
    <table style="width:100%;border-collapse:collapse;">
      <tr>
        <td style="padding:8px 0;color:#666;width:120px;vertical-align:top;">Customer</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.customer_name)}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Phone</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.customer_phone)}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Email</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.customer_email || "not provided")}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Address</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.address)}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Items</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.item_description)}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Notes</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.notes || "none")}</td>
      </tr>
    </table>
    """

    html_layout(content, operator)
  end

  defp customer_confirmation_html(job, operator) do
    content = """
    <h2 style="margin:0 0 16px 0;font-size:20px;color:#111;">We received your request</h2>
    <p style="margin:0 0 16px 0;color:#333;line-height:1.5;">
      Hi #{escape(job.customer_name)}, thanks for reaching out.
      Here's a summary of what you submitted:
    </p>
    <table style="width:100%;border-collapse:collapse;">
      <tr>
        <td style="padding:8px 0;color:#666;width:120px;vertical-align:top;">Pickup address</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.address)}</td>
      </tr>
      <tr>
        <td style="padding:8px 0;color:#666;vertical-align:top;">Items</td>
        <td style="padding:8px 0;color:#111;">#{escape(job.item_description)}</td>
      </tr>
    </table>
    <p style="margin:16px 0 0 0;color:#333;line-height:1.5;">
      We'll contact you shortly at #{escape(job.customer_phone)} to confirm your pickup.
    </p>
    """

    html_layout(content, operator)
  end

  defp html_layout(content, operator) do
    """
    <!DOCTYPE html>
    <html>
    <head><meta charset="utf-8"></head>
    <body style="margin:0;padding:0;background:#f4f4f4;font-family:Arial,Helvetica,sans-serif;">
      <div style="max-width:600px;margin:0 auto;background:#ffffff;">
        <div style="background:#222;padding:20px 24px;">
          <h1 style="margin:0;font-size:22px;color:#ffffff;font-weight:bold;">
            #{escape(operator[:business_name])}
          </h1>
        </div>
        <div style="padding:24px;">
          #{content}
        </div>
        <div style="background:#f8f8f8;padding:16px 24px;border-top:1px solid #eee;">
          <p style="margin:0;font-size:13px;color:#999;">
            #{escape(operator[:business_name])} &middot; #{escape(operator[:phone])}
          </p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp escape(nil), do: ""

  defp escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape(value), do: escape(to_string(value))
end
