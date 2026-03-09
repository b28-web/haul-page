defmodule HaulWeb.PlacesController do
  use HaulWeb, :controller

  def autocomplete(conn, %{"input" => input}) when byte_size(input) >= 3 do
    {:ok, suggestions} = Haul.Places.autocomplete(input)
    json(conn, %{suggestions: suggestions})
  end

  def autocomplete(conn, _params) do
    json(conn, %{suggestions: []})
  end
end
