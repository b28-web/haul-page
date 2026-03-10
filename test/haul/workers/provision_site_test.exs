defmodule Haul.Workers.ProvisionSiteTest do
  use Haul.DataCase, async: false

  alias Haul.AI.Conversation
  alias Haul.AI.OperatorProfile
  alias Haul.AI.OperatorProfile.ServiceOffering
  alias Haul.Workers.ProvisionSite

  setup do
    unique = System.unique_integer([:positive])
    biz_name = "Worker Test Co #{unique}"

    slug =
      biz_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    tenant = "tenant_#{slug}"

    on_exit(fn ->
      Ecto.Adapters.SQL.query(Haul.Repo, ~s(DROP SCHEMA IF EXISTS "#{tenant}" CASCADE))
    end)

    {:ok, conversation} =
      Conversation
      |> Ash.Changeset.for_create(:start, %{session_id: Ecto.UUID.generate()})
      |> Ash.create()

    profile = %OperatorProfile{
      business_name: biz_name,
      owner_name: "Worker Owner",
      phone: "555-8888",
      email: "worker-#{unique}@example.com",
      service_area: "Worker City",
      tagline: "We work it!",
      years_in_business: 3,
      services: [
        %ServiceOffering{name: "Junk Removal", description: nil, category: :junk_removal}
      ],
      differentiators: ["Fast service"]
    }

    %{conversation: conversation, profile: profile, slug: slug}
  end

  describe "enqueue/3" do
    test "creates an Oban job", %{conversation: conv, profile: profile} do
      session_id = Ecto.UUID.generate()
      assert {:ok, job} = ProvisionSite.enqueue(conv.id, profile, session_id)
      assert job.queue == "default"
      assert job.args["conversation_id"] == conv.id
      assert job.args["session_id"] == session_id
      assert is_map(job.args["profile"])
      assert job.args["profile"]["business_name"] == profile.business_name
    end
  end

  describe "perform/1" do
    test "provisions site and broadcasts success", %{
      conversation: conv,
      profile: profile,
      slug: slug
    } do
      session_id = Ecto.UUID.generate()
      Phoenix.PubSub.subscribe(Haul.PubSub, "provisioning:#{session_id}")

      job = %Oban.Job{
        args: %{
          "conversation_id" => conv.id,
          "session_id" => session_id,
          "profile" => %{
            "business_name" => profile.business_name,
            "owner_name" => "Worker Owner",
            "phone" => profile.phone,
            "email" => profile.email,
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
      assert result.site_url =~ slug
      assert result.company_name == profile.business_name
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
