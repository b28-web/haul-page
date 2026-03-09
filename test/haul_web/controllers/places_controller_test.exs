defmodule HaulWeb.PlacesControllerTest do
  use HaulWeb.ConnCase, async: true

  describe "GET /api/places/autocomplete" do
    test "returns suggestions for valid input (>= 3 chars)", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete", input: "123 Main")
      assert %{"suggestions" => suggestions} = json_response(conn, 200)
      assert length(suggestions) == 3

      first = List.first(suggestions)
      assert Map.has_key?(first, "place_id")
      assert Map.has_key?(first, "description")
      assert Map.has_key?(first, "structured_formatting")
      assert Map.has_key?(first["structured_formatting"], "main_text")
      assert Map.has_key?(first["structured_formatting"], "secondary_text")
    end

    test "returns empty suggestions for short input (< 3 chars)", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete", input: "ab")
      assert %{"suggestions" => []} = json_response(conn, 200)
    end

    test "returns empty suggestions for single char input", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete", input: "a")
      assert %{"suggestions" => []} = json_response(conn, 200)
    end

    test "returns empty suggestions when input param is missing", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete")
      assert %{"suggestions" => []} = json_response(conn, 200)
    end

    test "returns empty suggestions for empty input string", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete", input: "")
      assert %{"suggestions" => []} = json_response(conn, 200)
    end

    test "sandbox adapter receives the input", %{conn: conn} do
      get(conn, "/api/places/autocomplete", input: "123 Main")
      assert_received {:places_autocomplete, "123 Main"}
    end

    test "exactly 3 chars is accepted", %{conn: conn} do
      conn = get(conn, "/api/places/autocomplete", input: "abc")
      assert %{"suggestions" => suggestions} = json_response(conn, 200)
      assert length(suggestions) == 3
    end
  end
end
