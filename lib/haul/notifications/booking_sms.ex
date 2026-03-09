defmodule Haul.Notifications.BookingSMS do
  @moduledoc """
  Builds SMS message strings for booking notifications.
  """

  @doc """
  Operator alert SMS for a new booking.
  Format: "New booking from {name} — {phone}. {address}"
  Kept under 160 characters where possible.
  """
  def operator_alert(job) do
    "New booking from #{job.customer_name} — #{job.customer_phone}. #{job.address}"
  end
end
