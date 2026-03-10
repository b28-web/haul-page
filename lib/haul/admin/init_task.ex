defmodule Haul.Admin.InitTask do
  @moduledoc """
  Supervised task that bootstraps the superadmin account at startup.

  Placed in the supervision tree after Repo. Uses `:transient` restart so it
  stays down after success but retries on crash.
  """

  require Logger

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {Task, :start_link, [&run/0]},
      restart: :transient
    }
  end

  def run do
    Haul.Admin.Bootstrap.ensure_admin!()
  rescue
    error ->
      Logger.warning("[init] Admin bootstrap failed: #{inspect(error)}")
      reraise error, __STACKTRACE__
  end
end
