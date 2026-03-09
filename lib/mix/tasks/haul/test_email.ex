defmodule Mix.Tasks.Haul.TestEmail do
  @moduledoc "Send a test email to verify mailer configuration. Visible at /dev/mailbox in dev."
  @shortdoc "Send a test email via Haul.Mailer"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    to = List.first(args) || default_recipient()

    case Haul.Mailer.test_email(to) do
      {:ok, _} ->
        Mix.shell().info("Test email sent to #{to}. Check /dev/mailbox in your browser.")

      {:error, reason} ->
        Mix.shell().error("Failed to send test email: #{inspect(reason)}")
    end
  end

  defp default_recipient do
    operator = Application.get_env(:haul, :operator, [])
    Keyword.get(operator, :email, "test@example.com")
  end
end
