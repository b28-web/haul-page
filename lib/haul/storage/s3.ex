defmodule Haul.Storage.S3 do
  @moduledoc false

  def put_object(key, binary, content_type) do
    bucket = bucket()

    case ExAws.S3.put_object(bucket, key, binary, content_type: content_type)
         |> ExAws.request() do
      {:ok, _} -> {:ok, key}
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_object(key) do
    bucket = bucket()

    case ExAws.S3.delete_object(bucket, key) |> ExAws.request() do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def public_url(key) do
    bucket = bucket()
    host = ExAws.Config.new(:s3) |> Map.get(:host, "fly.storage.tigris.dev")
    "https://#{bucket}.#{host}/#{key}"
  end

  defp bucket do
    Application.get_env(:haul, :storage, [])[:bucket] ||
      raise "Missing :storage :bucket configuration"
  end
end
