defmodule Haul.Workers.CheckDunningGrace do
  @moduledoc false
  use Oban.Worker, queue: :default, max_attempts: 3

  require Ash.Query
  require Logger

  alias Haul.Accounts.Company

  @grace_period_days 7

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    cutoff = DateTime.add(DateTime.utc_now(), -@grace_period_days, :day)

    case list_companies_past_grace(cutoff) do
      {:ok, companies} ->
        Enum.each(companies, &downgrade_company/1)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp list_companies_past_grace(cutoff) do
    Company
    |> Ash.Query.filter(not is_nil(dunning_started_at) and dunning_started_at < ^cutoff)
    |> Ash.read()
  end

  defp downgrade_company(company) do
    case company
         |> Ash.Changeset.for_update(:update_company, %{
           subscription_plan: :starter,
           stripe_subscription_id: nil,
           dunning_started_at: nil
         })
         |> Ash.update() do
      {:ok, _} ->
        Logger.info("Dunning grace expired: company #{company.id} downgraded to starter")

      {:error, reason} ->
        Logger.warning("Dunning downgrade failed for company #{company.id}: #{inspect(reason)}")
    end
  end
end
