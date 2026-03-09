defmodule Haul.Workers.ProvisionSiteTest do
  use Haul.DataCase, async: false

  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.Workers.ProvisionSite

  @profile %OperatorProfile{
    business_name: "Worker Test Co",
    owner_name: "Worker Owner",
    phone: "555-8888",
    email: "worker@example.com",
    service_area: "Worker City",
    tagline: "We work it!",
    years_in_business: 3,
    services: [
      %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal}
    ],
    differentiators: ["Fast service"]
  }

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

    {:ok, conversation} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    %{conversation: conversation}
  end

  describe "enqueue/3" do
    test "creates an Oban job", %{conversation: conv} do
      session_id = Ecto.UUID.generate()
      assert {:ok, job} = ProvisionSite.enqueue(conv.id, @profile, session_id)
      assert job.queue == "default"
      assert job.args["conversation_id"] == conv.id
      assert job.args["session_id"] == session_id
      assert is_map(job.args["profile"])
      assert job.args["profile"]["business_name"] == "Worker Test Co"
    end
  end

  describe "perform/1" do
    test "provisions site and broadcasts success", %{conversation: conv} do
      session_id = Ecto.UUID.generate()
      Phoenix.PubSub.subscribe(Haul.PubSub, "provisioning:#{session_id}")

      job = %Oban.Job{
        args: %{
          "conversation_id" => conv.id,
          "session_id" => session_id,
          "profile" => %{
            "business_name" => "Worker Test Co",
            "owner_name" => "Worker Owner",
            "phone" => "555-8888",
            "email" => "worker@example.com",
            "service_area" => "Worker City",
            "tagline" => "We work it!",
            "years_in_business" => 3,
            "services" => [
              %{"name" => "Junk Removal", "description" => nil, "category" => "junk_removal"}
            ],
            "differentiators" => ["Fast service"]
          }
        }
      }

      assert :ok = ProvisionSite.perform(job)

      assert_receive {:provisioning_complete, result}
      assert result.site_url =~ "worker-test-co"
      assert result.company_name == "Worker Test Co"
      assert is_integer(result.duration_ms)
    end

    test "broadcasts failure on invalid profile", %{conversation: conv} do
      session_id = Ecto.UUID.generate()
      Phoenix.PubSub.subscribe(Haul.PubSub, "provisioning:#{session_id}")

      job = %Oban.Job{
        args: %{
          "conversation_id" => conv.id,
          "session_id" => session_id,
          "profile" => %{
            "business_name" => "Test",
            "services" => [],
            "differentiators" => []
          }
        }
      }

      assert {:error, _} = ProvisionSite.perform(job)

      assert_receive {:provisioning_failed, details}
      assert details.step == :validation
    end
  end
end
