defmodule Haul.Operations.Changes.EnqueueNotifications do
  @moduledoc false
  use Ash.Resource.Change

  alias Haul.Workers.SendBookingEmail
  alias Haul.Workers.SendBookingSMS

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, job ->
      tenant = job.__metadata__.tenant

      {:ok, _} = Oban.insert(SendBookingEmail.new(%{"job_id" => job.id, "tenant" => tenant}))
      {:ok, _} = Oban.insert(SendBookingSMS.new(%{"job_id" => job.id, "tenant" => tenant}))

      {:ok, job}
    end)
  end
end
