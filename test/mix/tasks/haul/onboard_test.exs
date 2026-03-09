defmodule Mix.Tasks.Haul.OnboardTest do
  use Haul.DataCase, async: false

  setup do
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

    :ok
  end

  describe "non-interactive mode" do
    test "onboards with all CLI flags" do
      Mix.Tasks.Haul.Onboard.run([
        "--name",
        "CLI Test Co",
        "--phone",
        "555-9999",
        "--email",
        "cli@example.com",
        "--area",
        "Portland, OR"
      ])

      # Verify company was created
      companies = Ash.read!(Haul.Accounts.Company)
      assert Enum.any?(companies, &(&1.slug == "cli-test-co"))
    end

    test "idempotent re-run via CLI" do
      args = [
        "--name",
        "Repeat Co",
        "--phone",
        "555-0000",
        "--email",
        "repeat@example.com",
        "--area",
        "Denver, CO"
      ]

      Mix.Tasks.Haul.Onboard.run(args)
      Mix.Tasks.Haul.Onboard.run(args)

      companies = Ash.read!(Haul.Accounts.Company)
      assert length(Enum.filter(companies, &(&1.slug == "repeat-co"))) == 1
    end

    test "works without phone and area" do
      Mix.Tasks.Haul.Onboard.run([
        "--name",
        "Bare Co",
        "--email",
        "bare@example.com"
      ])

      companies = Ash.read!(Haul.Accounts.Company)
      assert Enum.any?(companies, &(&1.slug == "bare-co"))
    end
  end
end
