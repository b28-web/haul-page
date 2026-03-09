defmodule HaulWeb.DebugController do
  use HaulWeb, :controller

  def error(_conn, _params) do
    raise "Sentry test error — if you see this in Sentry, integration is working"
  end
end
