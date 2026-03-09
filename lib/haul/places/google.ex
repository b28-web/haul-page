defmodule Haul.Places.Google do
  @moduledoc """
  Places adapter that calls the Google Places (New) Autocomplete API.
  """

  @behaviour Haul.Places

  require Logger

  @api_url "https://places.googleapis.com/v1/places:autocomplete"

  @impl true
  def autocomplete(input) do
    case Application.get_env(:haul, :google_places_api_key) do
      nil ->
        Logger.warning("GOOGLE_PLACES_API_KEY not configured — returning empty suggestions")
        {:ok, []}

      api_key ->
        call_api(input, api_key)
    end
  end

  defp call_api(input, api_key) do
    case Req.post(@api_url,
           json: %{input: input, languageCode: "en"},
           headers: [{"X-Goog-Api-Key", api_key}]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, format_suggestions(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("Google Places API error: status=#{status} body=#{inspect(body)}")
        {:ok, []}

      {:error, reason} ->
        Logger.warning("Google Places API request failed: #{inspect(reason)}")
        {:ok, []}
    end
  end

  @doc false
  def format_suggestions(%{"suggestions" => suggestions}) when is_list(suggestions) do
    Enum.flat_map(suggestions, fn
      %{"placePrediction" => prediction} ->
        [format_prediction(prediction)]

      _other ->
        []
    end)
  end

  def format_suggestions(_), do: []

  defp format_prediction(prediction) do
    structured = Map.get(prediction, "structuredFormat", %{})

    %{
      place_id: get_in(prediction, ["placeId"]) || "",
      description: get_in(prediction, ["text", "text"]) || "",
      structured_formatting: %{
        main_text: get_in(structured, ["mainText", "text"]) || "",
        secondary_text: get_in(structured, ["secondaryText", "text"]) || ""
      }
    }
  end
end
