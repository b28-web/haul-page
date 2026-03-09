defmodule Haul.Workers.SendBookingEmail do
  @moduledoc false
  use Oban.Worker, queue: :notifications, max_attempts: 3

  alias Haul.Mailer
  alias Haul.Notifications.BookingEmail
  alias Haul.Operations.Job

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"job_id" => job_id, "tenant" => tenant}}) do
    case Ash.get(Job, job_id, tenant: tenant) do
      {:ok, job} ->
        job |> BookingEmail.operator_alert() |> Mailer.deliver()

        if job.customer_email do
          job |> BookingEmail.customer_confirmation() |> Mailer.deliver()
        end

        :ok

      {:error, _} ->
        :ok
    end
  end
end
