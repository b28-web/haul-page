defmodule Haul.Formatting do
  @moduledoc false

  @plan_ranks %{starter: 0, pro: 1, business: 2, dedicated: 3}

  @doc """
  Numeric rank for plan comparison. Higher rank = higher tier.
  """
  def plan_rank(plan), do: Map.get(@plan_ranks, plan, 0)

  @doc """
  Human-readable plan name.
  """
  def plan_name(:starter), do: "Starter"
  def plan_name(:pro), do: "Pro"
  def plan_name(:business), do: "Business"
  def plan_name(:dedicated), do: "Dedicated"
  def plan_name(_), do: "Unknown"

  @doc """
  Format cents as monthly price. 0 → "Free", else "$X/mo".
  """
  def format_price(0), do: "Free"

  def format_price(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    "$#{dollars}/mo"
  end

  @doc """
  Format cents as dollar amount with cents. "$X.XX"
  """
  def format_amount(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    remaining = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(Integer.to_string(remaining), 2, "0")}"
  end

  @doc """
  Days remaining in dunning grace period (7-day default).
  """
  def days_until_downgrade(dunning_started_at) do
    grace_days = 7
    elapsed = DateTime.diff(DateTime.utc_now(), dunning_started_at, :day)
    max(grace_days - elapsed, 0)
  end

  @doc """
  CSS class for plan badge.
  """
  def plan_badge_class(:starter), do: "rounded px-2 py-0.5 text-xs bg-zinc-700 text-zinc-300"
  def plan_badge_class(:pro), do: "rounded px-2 py-0.5 text-xs bg-blue-900 text-blue-300"

  def plan_badge_class(:business),
    do: "rounded px-2 py-0.5 text-xs bg-purple-900 text-purple-300"

  def plan_badge_class(:dedicated),
    do: "rounded px-2 py-0.5 text-xs bg-amber-900 text-amber-300"

  def plan_badge_class(_), do: "rounded px-2 py-0.5 text-xs bg-zinc-700 text-zinc-300"

  @doc """
  Star rating display. nil → nil, 3 → "★★★☆☆"
  """
  def star_display(nil), do: nil

  def star_display(rating) when is_integer(rating) do
    String.duplicate("★", rating) <> String.duplicate("☆", 5 - rating)
  end

  @doc """
  Endorsement source label. nil → nil, :google → "Google", etc.
  """
  def source_label(nil), do: nil
  def source_label(:google), do: "Google"
  def source_label(:yelp), do: "Yelp"
  def source_label(:direct), do: "Direct"
  def source_label(:facebook), do: "Facebook"
end
