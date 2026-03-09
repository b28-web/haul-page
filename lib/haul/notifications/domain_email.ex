defmodule Haul.Notifications.DomainEmail do
  @moduledoc false
  import Swoosh.Email

  def cert_failed(company, domain) do
    operator = Application.get_env(:haul, :operator, [])
    from_name = Keyword.get(operator, :business_name, "Haul")
    from_email = Keyword.get(operator, :email, "noreply@example.com")

    new()
    |> to({company.name, from_email})
    |> from({from_name, from_email})
    |> subject("SSL certificate failed for #{domain}")
    |> text_body("""
    Hi #{company.name},

    We were unable to provision an SSL certificate for #{domain} after \
    multiple attempts. This usually means the DNS record is not yet \
    propagated or there's an issue with Let's Encrypt.

    Please check your DNS settings and try again from your domain \
    settings page. If the issue persists, contact support.

    — #{from_name}
    """)
  end
end
