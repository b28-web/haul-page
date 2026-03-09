defmodule Haul.Mailer do
  use Swoosh.Mailer, otp_app: :haul

  import Swoosh.Email

  @doc """
  Build and deliver a test email. Useful for verifying mailer config.
  In dev, the email appears at `/dev/mailbox`.
  """
  def test_email(to) do
    operator = Application.get_env(:haul, :operator, [])
    from_name = Keyword.get(operator, :business_name, "Haul")
    from_email = Keyword.get(operator, :email, "noreply@example.com")

    email =
      new()
      |> to(to)
      |> from({from_name, from_email})
      |> subject("Test email from #{from_name}")
      |> text_body("This is a test email. Your mailer is configured correctly.")

    deliver(email)
  end
end
