defmodule Haul.Content.Loader do
  @moduledoc """
  Loads gallery and endorsement data from JSON files in priv/content/.

  This is a bridge module — it will be replaced by Ash resource queries
  when the Haul.Content domain is implemented.
  """

  @doc """
  Reads JSON content files and caches them in persistent_term.
  Called once at application startup.
  """
  def load! do
    gallery = read_json!("gallery.json")
    endorsements = read_json!("endorsements.json")

    :persistent_term.put({__MODULE__, :gallery_items}, gallery)
    :persistent_term.put({__MODULE__, :endorsements}, endorsements)

    :ok
  end

  @doc """
  Returns the list of gallery items.
  Each item is a map with atom keys: :before_photo_url, :after_photo_url, :caption.
  """
  def gallery_items do
    :persistent_term.get({__MODULE__, :gallery_items})
  end

  @doc """
  Returns the list of endorsements.
  Each item is a map with atom keys: :customer_name, :quote_text, :star_rating, :date.
  """
  def endorsements do
    :persistent_term.get({__MODULE__, :endorsements})
  end

  defp read_json!(filename) do
    :haul
    |> :code.priv_dir()
    |> Path.join("content/#{filename}")
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
  end
end
