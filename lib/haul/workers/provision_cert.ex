defmodule Haul.Workers.ProvisionCert do
  @moduledoc false
  use Oban.Worker, queue: :certs, max_attempts: 3

  require Logger

  alias Haul.Accounts.Company
  alias Haul.Domains
  alias Haul.Notifications.DomainEmail

  @poll_interval_ms 5_000
  @max_polls 24

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "add", "company_id" => company_id}} = job) do
    with {:ok, company} <- Ash.get(Company, company_id),
         domain when is_binary(domain) <- company.domain do
      case provision_and_poll(domain) do
        :ok ->
          activate_domain(company)

        {:error, reason} ->
          if job.attempt >= job.max_attempts do
            Logger.warning("Cert provisioning exhausted for #{domain}: #{inspect(reason)}")
            send_failure_notification(company, domain)
          end

          {:error, reason}
      end
    else
      nil ->
        Logger.warning("ProvisionCert: company #{company_id} has no domain set")
        :ok

      {:error, reason} ->
        Logger.warning("ProvisionCert: failed to load company #{company_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def perform(%Oban.Job{args: %{"action" => "remove", "domain" => domain}}) do
    case Domains.remove_cert(domain) do
      :ok ->
        Logger.info("Cert removed for #{domain}")
        :ok

      {:error, reason} ->
        Logger.warning("Cert removal failed for #{domain}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def perform(%Oban.Job{args: args}) do
    Logger.warning("ProvisionCert: unknown args #{inspect(args)}")
    :ok
  end

  defp provision_and_poll(domain) do
    case Domains.add_cert(domain) do
      {:ok, _} ->
        poll_until_ready(domain, 0)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp poll_until_ready(_domain, count) when count >= @max_polls do
    {:error, :timeout}
  end

  defp poll_until_ready(domain, count) do
    case Domains.check_cert(domain) do
      {:ok, :ready} ->
        :ok

      {:ok, :pending} ->
        Process.sleep(@poll_interval_ms)
        poll_until_ready(domain, count + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp activate_domain(company) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case company
         |> Ash.Changeset.for_update(:update_company, %{
           domain_status: :active,
           domain_verified_at: now
         })
         |> Ash.update() do
      {:ok, updated} ->
        Logger.info("Domain #{updated.domain} activated for company #{updated.id}")
        broadcast_status(updated)
        :ok

      {:error, reason} ->
        Logger.warning("Failed to activate domain for company #{company.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp broadcast_status(company) do
    Phoenix.PubSub.broadcast(
      Haul.PubSub,
      "domain:#{company.id}",
      {:domain_status_changed, company.domain_status}
    )
  end

  defp send_failure_notification(company, domain) do
    email = DomainEmail.cert_failed(company, domain)
    Haul.Mailer.deliver(email)
  rescue
    error ->
      Logger.warning("Failed to send cert failure notification: #{inspect(error)}")
  end
end
