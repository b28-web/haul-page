defmodule Haul.Storage do
  @moduledoc false

  @doc """
  Upload a file to storage. Returns `{:ok, key}` or `{:error, reason}`.
  """
  def put_object(key, binary, content_type) do
    case backend() do
      :local -> Haul.Storage.Local.put_object(key, binary, content_type)
      :s3 -> Haul.Storage.S3.put_object(key, binary, content_type)
    end
  end

  @doc """
  Delete a file from storage. Returns `:ok` or `{:error, reason}`.
  """
  def delete_object(key) do
    case backend() do
      :local -> Haul.Storage.Local.delete_object(key)
      :s3 -> Haul.Storage.S3.delete_object(key)
    end
  end

  @doc """
  Generate a public URL for a stored object.
  """
  def public_url(key) do
    case backend() do
      :local -> Haul.Storage.Local.public_url(key)
      :s3 -> Haul.Storage.S3.public_url(key)
    end
  end

  @doc """
  Generate a unique storage key for an upload.
  """
  def upload_key(tenant, prefix, filename) do
    ext = Path.extname(filename) |> String.downcase()
    uuid = Ecto.UUID.generate()
    "#{tenant}/#{prefix}/#{uuid}#{ext}"
  end

  defp backend do
    Application.get_env(:haul, :storage, [])[:backend] || :local
  end
end
