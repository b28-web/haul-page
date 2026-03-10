defmodule Haul.Admin.AccountHelpers do
  @moduledoc false

  @doc """
  Filter companies by case-insensitive match on slug or name.
  """
  def filter_companies(companies, ""), do: companies

  def filter_companies(companies, term) do
    term = String.downcase(term)

    Enum.filter(companies, fn c ->
      String.contains?(String.downcase(c.slug), term) ||
        String.contains?(String.downcase(c.name), term)
    end)
  end

  @doc """
  Sort companies by a given field and direction.
  """
  def sort_companies(companies, :name, dir) do
    Enum.sort_by(companies, &String.downcase(&1.name), dir)
  end

  def sort_companies(companies, :slug, dir) do
    Enum.sort_by(companies, &String.downcase(&1.slug), dir)
  end

  def sort_companies(companies, :inserted_at, dir) do
    Enum.sort_by(companies, & &1.inserted_at, {dir, DateTime})
  end

  def sort_companies(companies, _field, _dir), do: companies

  @doc """
  Toggle sort direction.
  """
  def toggle_dir(:asc), do: :desc
  def toggle_dir(:desc), do: :asc

  @doc """
  Sort indicator arrow for table headers.
  """
  def sort_indicator(field, field, :asc), do: "↑"
  def sort_indicator(field, field, :desc), do: "↓"
  def sort_indicator(_field, _sort_by, _dir), do: ""
end
