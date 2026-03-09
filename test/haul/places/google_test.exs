defmodule Haul.Places.GoogleTest do
  use ExUnit.Case, async: true

  alias Haul.Places.Google

  describe "format_suggestions/1" do
    test "formats a typical Google Places API response" do
      response = %{
        "suggestions" => [
          %{
            "placePrediction" => %{
              "placeId" => "ChIJd8BlQ2BZwokRAFUEcm_qrcA",
              "text" => %{"text" => "123 Main St, New York, NY 10001, USA"},
              "structuredFormat" => %{
                "mainText" => %{"text" => "123 Main St"},
                "secondaryText" => %{"text" => "New York, NY 10001, USA"}
              }
            }
          },
          %{
            "placePrediction" => %{
              "placeId" => "ChIJaXQRs6lZwokRY6EFpJnhNNE",
              "text" => %{"text" => "123 Main Ave, Springfield, IL, USA"},
              "structuredFormat" => %{
                "mainText" => %{"text" => "123 Main Ave"},
                "secondaryText" => %{"text" => "Springfield, IL, USA"}
              }
            }
          }
        ]
      }

      result = Google.format_suggestions(response)
      assert length(result) == 2

      first = List.first(result)
      assert first.place_id == "ChIJd8BlQ2BZwokRAFUEcm_qrcA"
      assert first.description == "123 Main St, New York, NY 10001, USA"
      assert first.structured_formatting.main_text == "123 Main St"
      assert first.structured_formatting.secondary_text == "New York, NY 10001, USA"
    end

    test "handles empty suggestions list" do
      assert Google.format_suggestions(%{"suggestions" => []}) == []
    end

    test "handles missing suggestions key" do
      assert Google.format_suggestions(%{}) == []
    end

    test "handles nil input" do
      assert Google.format_suggestions(nil) == []
    end

    test "skips non-place suggestions (e.g. query suggestions)" do
      response = %{
        "suggestions" => [
          %{"querySuggestion" => %{"text" => "pizza near me"}},
          %{
            "placePrediction" => %{
              "placeId" => "ChIJ123",
              "text" => %{"text" => "Pizza Place, Chicago, IL"},
              "structuredFormat" => %{
                "mainText" => %{"text" => "Pizza Place"},
                "secondaryText" => %{"text" => "Chicago, IL"}
              }
            }
          }
        ]
      }

      result = Google.format_suggestions(response)
      assert length(result) == 1
      assert List.first(result).place_id == "ChIJ123"
    end

    test "handles missing fields gracefully" do
      response = %{
        "suggestions" => [
          %{"placePrediction" => %{}}
        ]
      }

      [result] = Google.format_suggestions(response)
      assert result.place_id == ""
      assert result.description == ""
      assert result.structured_formatting.main_text == ""
      assert result.structured_formatting.secondary_text == ""
    end
  end
end
