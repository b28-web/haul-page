defmodule Haul.Storage.Local do
  @moduledoc false

  @upload_dir "priv/uploads"

  def put_object(key, binary, _content_type) do
    path = file_path(key)
    File.mkdir_p!(Path.dirname(path))

    case File.write(path, binary) do
      :ok -> {:ok, key}
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_object(key) do
    path = file_path(key)

    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def public_url(key) do
    "/uploads/#{key}"
  end

  defp file_path(key) do
    Path.join(Application.app_dir(:haul, @upload_dir), key)
  end
end
