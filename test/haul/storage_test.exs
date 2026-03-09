defmodule Haul.StorageTest do
  use ExUnit.Case, async: true

  alias Haul.Storage

  @test_binary <<137, 80, 78, 71, 13, 10, 26, 10>>
  @test_content_type "image/png"

  describe "upload_key/3" do
    test "generates key with tenant, prefix, and extension" do
      key = Storage.upload_key("tenant_test", "jobs", "photo.jpg")
      assert String.starts_with?(key, "tenant_test/jobs/")
      assert String.ends_with?(key, ".jpg")
    end

    test "generates unique keys" do
      key1 = Storage.upload_key("tenant_test", "jobs", "photo.jpg")
      key2 = Storage.upload_key("tenant_test", "jobs", "photo.jpg")
      refute key1 == key2
    end

    test "normalizes extension to lowercase" do
      key = Storage.upload_key("tenant_test", "jobs", "photo.JPG")
      assert String.ends_with?(key, ".jpg")
    end
  end

  describe "local backend" do
    setup do
      key = Storage.upload_key("tenant_test", "test", "test.png")

      on_exit(fn ->
        Storage.delete_object(key)
      end)

      %{key: key}
    end

    test "put_object writes file and returns key", %{key: key} do
      assert {:ok, ^key} = Storage.put_object(key, @test_binary, @test_content_type)
    end

    test "delete_object removes file", %{key: key} do
      {:ok, _} = Storage.put_object(key, @test_binary, @test_content_type)
      assert :ok = Storage.delete_object(key)
    end

    test "delete_object returns ok for missing file" do
      assert :ok = Storage.delete_object("nonexistent/file.png")
    end

    test "public_url returns path with /uploads/ prefix", %{key: key} do
      url = Storage.public_url(key)
      assert String.starts_with?(url, "/uploads/")
      assert String.contains?(url, key)
    end
  end
end
