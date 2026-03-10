defmodule Haul.AI.ErrorClassifierTest do
  use ExUnit.Case, async: true

  alias Haul.AI.ErrorClassifier

  describe "transient?/1" do
    test "timeout is transient" do
      assert ErrorClassifier.transient?({:error, :timeout})
    end

    test "rate_limited is transient" do
      assert ErrorClassifier.transient?({:error, :rate_limited})
    end

    test "econnrefused is transient" do
      assert ErrorClassifier.transient?({:error, :econnrefused})
    end

    test "HTTP 429 is transient" do
      assert ErrorClassifier.transient?({:error, %{status: 429}})
    end

    test "HTTP 500 is transient" do
      assert ErrorClassifier.transient?({:error, %{status: 500}})
    end

    test "HTTP 502 is transient" do
      assert ErrorClassifier.transient?({:error, %{status: 502}})
    end

    test "HTTP 503 is transient" do
      assert ErrorClassifier.transient?({:error, %{status: 503}})
    end

    test "HTTP 400 is not transient" do
      refute ErrorClassifier.transient?({:error, %{status: 400}})
    end

    test "HTTP 401 is not transient" do
      refute ErrorClassifier.transient?({:error, %{status: 401}})
    end

    test "HTTP 404 is not transient" do
      refute ErrorClassifier.transient?({:error, %{status: 404}})
    end

    test "invalid_request is not transient" do
      refute ErrorClassifier.transient?({:error, :invalid_request})
    end

    test "generic string error is not transient" do
      refute ErrorClassifier.transient?({:error, "something went wrong"})
    end

    test "ok tuple is not transient" do
      refute ErrorClassifier.transient?({:ok, "success"})
    end

    test "nil is not transient" do
      refute ErrorClassifier.transient?(nil)
    end
  end
end
