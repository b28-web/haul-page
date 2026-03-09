defmodule Haul.Workers.CheckDunningGraceTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Company
  alias Haul.Workers.CheckDunningGrace

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Dunning Test Co",
        slug: "dunning-test-co"
      })
      |> Ash.create()

    {:ok, company} =
      company
      |> Ash.Changeset.for_update(:update_company, %{
        stripe_customer_id: "cus_dunning",
        stripe_subscription_id: "sub_dunning",
        subscription_plan: :pro
      })
      |> Ash.update()

    on_exit(fn ->
      {:ok, result} =
        Ecto.Adapters.SQL.query(Haul.Repo, """
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name LIKE 'tenant_%'
        """)

      for [schema] <- result.rows do
        Ecto.Adapters.SQL.query!(Haul.Repo, "DROP SCHEMA \"#{schema}\" CASCADE")
      end
    end)

    %{company: company}
  end

  test "downgrades company past 7-day grace period", %{company: company} do
    # Set dunning to 8 days ago
    past = DateTime.add(DateTime.utc_now(), -8, :day)

    {:ok, _} =
      company
      |> Ash.Changeset.for_update(:update_company, %{dunning_started_at: past})
      |> Ash.update()

    assert :ok = CheckDunningGrace.perform(%Oban.Job{})

    {:ok, updated} = Ash.get(Company, company.id)
    assert updated.subscription_plan == :starter
    assert is_nil(updated.stripe_subscription_id)
    assert is_nil(updated.dunning_started_at)
  end

  test "does not downgrade company within 7-day grace period", %{company: company} do
    # Set dunning to 3 days ago
    recent = DateTime.add(DateTime.utc_now(), -3, :day)

    {:ok, _} =
      company
      |> Ash.Changeset.for_update(:update_company, %{dunning_started_at: recent})
      |> Ash.update()

    assert :ok = CheckDunningGrace.perform(%Oban.Job{})

    {:ok, updated} = Ash.get(Company, company.id)
    assert updated.subscription_plan == :pro
    assert updated.stripe_subscription_id == "sub_dunning"
    assert not is_nil(updated.dunning_started_at)
  end

  test "ignores companies without dunning state", %{company: company} do
    assert :ok = CheckDunningGrace.perform(%Oban.Job{})

    {:ok, updated} = Ash.get(Company, company.id)
    assert updated.subscription_plan == :pro
  end
end
