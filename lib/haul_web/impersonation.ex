defmodule HaulWeb.Impersonation do
  @moduledoc """
  Impersonation session management for superadmin.

  Allows an authenticated admin to view the /app panel as any tenant operator.
  Session keys: "impersonating_slug", "impersonating_since", "real_admin_id".
  Auto-expires after 1 hour.
  """
  import Plug.Conn
  require Logger

  alias Haul.Admin.AdminUser
  alias Haul.Accounts.Company
  alias AshAuthentication.Jwt

  require Ash.Query

  @max_duration_seconds 3600

  @doc """
  Returns true if impersonation keys are present in the session map.
  """
  def active?(session) when is_map(session) do
    is_binary(session["impersonating_slug"])
  end

  @doc """
  Returns true if the impersonation session has exceeded the 1-hour limit.
  """
  def expired?(session) when is_map(session) do
    case session["impersonating_since"] do
      since when is_binary(since) ->
        case DateTime.from_iso8601(since) do
          {:ok, started_at, _} ->
            DateTime.diff(DateTime.utc_now(), started_at) > @max_duration_seconds

          _ ->
            true
        end

      _ ->
        true
    end
  end

  @doc """
  Returns the number of minutes remaining in the impersonation session.
  """
  def remaining_minutes(session) when is_map(session) do
    case session["impersonating_since"] do
      since when is_binary(since) ->
        case DateTime.from_iso8601(since) do
          {:ok, started_at, _} ->
            elapsed = DateTime.diff(DateTime.utc_now(), started_at)
            remaining = div(@max_duration_seconds - elapsed, 60)
            max(0, remaining)

          _ ->
            0
        end

      _ ->
        0
    end
  end

  @doc """
  Sets impersonation session keys and logs the start event.
  """
  def start_session(conn, %AdminUser{} = admin, slug) do
    Logger.warning(
      "Impersonation started: admin=#{admin.email} target=#{slug}",
      event: "impersonation_start",
      admin_user_id: admin.id,
      admin_email: admin.email,
      target_slug: slug,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )

    conn
    |> put_session("impersonating_slug", slug)
    |> put_session("impersonating_since", DateTime.utc_now() |> DateTime.to_iso8601())
    |> put_session("real_admin_id", admin.id)
  end

  @doc """
  Clears impersonation session keys and logs the event.
  """
  def end_session(conn, reason \\ :manual) do
    slug = get_session(conn, "impersonating_slug")
    admin_id = get_session(conn, "real_admin_id")

    event =
      case reason do
        :expired -> "impersonation_expired"
        _ -> "impersonation_end"
      end

    if slug do
      Logger.warning(
        "Impersonation #{reason}: admin_id=#{admin_id} target=#{slug}",
        event: event,
        admin_user_id: admin_id,
        target_slug: slug,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      )
    end

    conn
    |> delete_session("impersonating_slug")
    |> delete_session("impersonating_since")
    |> delete_session("real_admin_id")
  end

  @doc """
  Validates admin JWT token from the session map. Returns {:ok, admin} or :error.
  """
  def check_admin_session(session) when is_map(session) do
    case session["_admin_user_token"] do
      token when is_binary(token) ->
        case Jwt.verify(token, AdminUser) do
          {:ok, %{"sub" => subject}, _} ->
            case AshAuthentication.subject_to_user(subject, AdminUser) do
              {:ok, %AdminUser{setup_completed: true} = admin} -> {:ok, admin}
              _ -> :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  @doc """
  Full validation: checks admin session, impersonation keys, expiry, and loads Company.
  Returns {:ok, admin, company} | :not_impersonating | {:expired, admin_id}
  """
  def validate_and_load(session) when is_map(session) do
    if active?(session) do
      case check_admin_session(session) do
        {:ok, admin} ->
          if expired?(session) do
            {:expired, admin.id}
          else
            slug = session["impersonating_slug"]

            case load_company(slug) do
              {:ok, company} -> {:ok, admin, company}
              _ -> :not_impersonating
            end
          end

        :error ->
          :not_impersonating
      end
    else
      :not_impersonating
    end
  end

  defp load_company(slug) do
    Company
    |> Ash.Query.filter(slug == ^slug)
    |> Ash.read_one()
    |> case do
      {:ok, %Company{} = company} -> {:ok, company}
      _ -> :error
    end
  end
end
