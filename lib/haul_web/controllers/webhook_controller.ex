defmodule HaulWeb.WebhookController do
  use HaulWeb, :controller

  require Logger

  alias Haul.Operations.Job

  def stripe(conn, _params) do
    raw_body = conn.assigns[:raw_body] || ""
    signature = get_req_header(conn, "stripe-signature") |> List.first() || ""
    secret = Application.get_env(:haul, :stripe_webhook_secret, "")

    case Haul.Payments.verify_webhook_signature(raw_body, signature, secret) do
      {:ok, event} ->
        handle_event(event)
        json(conn, %{status: "ok"})

      {:error, _reason} ->
        conn
        |> put_status(400)
        |> json(%{error: "invalid_signature"})
    end
  end

  defp handle_event(%{"type" => "payment_intent.succeeded"} = event) do
    metadata = get_metadata(event) || %{}

    case {metadata["job_id"], metadata["tenant"]} do
      {job_id, tenant} when is_binary(job_id) and is_binary(tenant) ->
        payment_intent_id = get_in(event, ["data", "object", "id"])

        case Ash.get(Job, job_id, tenant: tenant) do
          {:ok, job} ->
            case Ash.update(job, %{payment_intent_id: payment_intent_id},
                   action: :record_payment,
                   tenant: tenant
                 ) do
              {:ok, _job} ->
                Logger.info("Webhook: payment recorded for job #{job_id}")

              {:error, reason} ->
                Logger.warning("Webhook: failed to update job #{job_id}: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.warning("Webhook: job lookup failed: #{inspect(reason)}")
        end

      _ ->
        Logger.warning("Webhook: payment_intent.succeeded missing metadata")
    end
  end

  defp handle_event(%{"type" => "payment_intent.payment_failed"} = event) do
    case get_metadata(event) do
      %{"job_id" => job_id} ->
        Logger.warning("Webhook: payment failed for job #{job_id}")

      _ ->
        Logger.warning("Webhook: payment_intent.payment_failed missing metadata")
    end
  end

  defp handle_event(%{"type" => type}) do
    Logger.debug("Webhook: ignoring event type #{type}")
  end

  defp handle_event(_), do: :ok

  defp get_metadata(event) do
    get_in(event, ["data", "object", "metadata"])
  end
end
