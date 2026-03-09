defmodule Haul.Notifications.BillingEmail do
  @moduledoc false
  import Swoosh.Email

  def payment_failed(company) do
    operator = Application.get_env(:haul, :operator, [])
    from_name = Keyword.get(operator, :business_name, "Haul")
    from_email = Keyword.get(operator, :email, "noreply@example.com")

    new()
    |> to({company.name, from_email})
    |> from({from_name, from_email})
    |> subject("Payment failed — action needed")
    |> text_body("""
    Hi #{company.name},

    We were unable to process your subscription payment. Stripe will retry \
    automatically, but if the issue persists your plan may be downgraded \
    after a 7-day grace period.

    Please update your payment method in your billing settings to avoid \
    any interruption to your service.

    — #{from_name}
    """)
  end
end
