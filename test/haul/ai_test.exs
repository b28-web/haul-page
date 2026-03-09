defmodule Haul.AITest do
  use ExUnit.Case, async: true

  describe "call_function/2 with sandbox adapter" do
    test "ExtractName returns fixture response" do
      assert {:ok, result} =
               Haul.AI.call_function("ExtractName", %{"text" => "My name is Jane Smith"})

      assert result["first_name"] == "John"
      assert result["last_name"] == "Doe"
    end

    test "unknown function returns generic sandbox response" do
      assert {:ok, %{"result" => "sandbox"}} = Haul.AI.call_function("UnknownFunction", %{})
    end
  end
end
