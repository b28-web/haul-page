defmodule Haul.Workers.SendBookingSMS do
  @moduledoc false
  use Oban.Worker, queue: :notifications, max_attempts: 3

  alias Haul.Notifications.BookingSMS
  alias Haul.Operations.Job
  alias Haul.SMS

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"job_id" => job_id, "tenant" => tenant}}) do
    case Ash.get(Job, job_id, tenant: tenant) do
      {:ok, job} ->
        operator = Application.get_env(:haul, :operator, [])
        body = BookingSMS.operator_alert(job)
        SMS.send_sms(operator[:phone], body)
        :ok

      {:error, _} ->
        :ok
    end
  end
end
