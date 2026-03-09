defmodule Haul.Places.Sandbox do
  @moduledoc """
  Places adapter for dev/test. Returns static suggestions and notifies
  the calling process so tests can assert on autocomplete calls.
  """

  @behaviour Haul.Places

  require Logger

  @impl true
  def autocomplete(input) do
    suggestions = [
      %{
        place_id: "sandbox-place-1",
        description: "123 Main St, Springfield, IL 62701, USA",
        structured_formatting: %{
          main_text: "123 Main St",
          secondary_text: "Springfield, IL 62701, USA"
        }
      },
      %{
        place_id: "sandbox-place-2",
        description: "456 Oak Ave, Springfield, IL 62702, USA",
        structured_formatting: %{
          main_text: "456 Oak Ave",
          secondary_text: "Springfield, IL 62702, USA"
        }
      },
      %{
        place_id: "sandbox-place-3",
        description: "789 Elm Dr, Springfield, IL 62703, USA",
        structured_formatting: %{
          main_text: "789 Elm Dr",
          secondary_text: "Springfield, IL 62703, USA"
        }
      }
    ]

    Logger.info("[Places Sandbox] autocomplete: #{input}")
    send(self(), {:places_autocomplete, input})

    {:ok, suggestions}
  end
end
