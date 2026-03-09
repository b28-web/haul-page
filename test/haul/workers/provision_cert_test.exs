defmodule Haul.Workers.ProvisionCertTest do
  use Haul.DataCase, async: false

  alias Haul.Accounts.Company
  alias Haul.Workers.ProvisionCert

  setup do
    {:ok, company} =
      Company
      |> Ash.Changeset.for_create(:create_company, %{
        name: "Cert Test Co",
        slug: "cert-test-co"
      })
      |> Ash.create()

    {:ok, company} =
      company
      |> Ash.Changeset.for_update(:update_company, %{
        subscription_plan: :pro,
        domain: "custom.example.com",
        domain_status: :provisioning
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

  describe "add action" do
    test "provisions cert and activates domain", %{company: company} do
      job = %Oban.Job{
        args: %{"action" => "add", "company_id" => company.id},
        attempt: 1,
        max_attempts: 3
      }

      assert :ok = ProvisionCert.perform(job)

      {:ok, updated} = Ash.get(Company, company.id)
      assert updated.domain_status == :active
      assert updated.domain == "custom.example.com"
      assert not is_nil(updated.domain_verified_at)
    end

    test "handles company with no domain set", %{company: company} do
      {:ok, company} =
        company
        |> Ash.Changeset.for_update(:update_company, %{domain: nil, domain_status: nil})
        |> Ash.update()

      job = %Oban.Job{
        args: %{"action" => "add", "company_id" => company.id},
        attempt: 1,
        max_attempts: 3
      }

      assert :ok = ProvisionCert.perform(job)
    end

    test "handles non-existent company" do
      job = %Oban.Job{
        args: %{
          "action" => "add",
          "company_id" => Ash.UUID.generate()
        },
        attempt: 1,
        max_attempts: 3
      }

      assert {:error, _} = ProvisionCert.perform(job)
    end

    test "broadcasts PubSub on domain activation", %{company: company} do
      Phoenix.PubSub.subscribe(Haul.PubSub, "domain:#{company.id}")

      job = %Oban.Job{
        args: %{"action" => "add", "company_id" => company.id},
        attempt: 1,
        max_attempts: 3
      }

      assert :ok = ProvisionCert.perform(job)

      assert_receive {:domain_status_changed, :active}
    end
  end

  describe "remove action" do
    test "removes cert successfully", %{company: company} do
      job = %Oban.Job{
        args: %{
          "action" => "remove",
          "company_id" => company.id,
          "domain" => "custom.example.com"
        },
        attempt: 1,
        max_attempts: 3
      }

      assert :ok = ProvisionCert.perform(job)
    end
  end

  describe "unknown action" do
    test "handles unknown args gracefully" do
      job = %Oban.Job{
        args: %{"action" => "unknown"},
        attempt: 1,
        max_attempts: 3
      }

      assert :ok = ProvisionCert.perform(job)
    end
  end
end
