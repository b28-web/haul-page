defmodule Haul.RateLimiter do
  @moduledoc """
  ETS-based rate limiter. Tracks request counts per key within sliding windows.
  """
  use GenServer

  @table __MODULE__
  @cleanup_interval :timer.minutes(1)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check if a request is allowed under the rate limit.

  Returns `:ok` if allowed, `{:error, :rate_limited}` if over limit.
  """
  @spec check_rate(term(), pos_integer(), pos_integer()) :: :ok | {:error, :rate_limited}
  def check_rate(key, limit, window_seconds) do
    now = System.system_time(:second)
    window_start = now - window_seconds

    # Clean old entries for this key and count recent ones
    entries = :ets.lookup(@table, key)

    recent =
      entries
      |> Enum.map(fn {_key, timestamp} -> timestamp end)
      |> Enum.filter(&(&1 >= window_start))

    if length(recent) >= limit do
      {:error, :rate_limited}
    else
      :ets.insert(@table, {key, now})
      :ok
    end
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :duplicate_bag, :public])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cutoff = System.system_time(:second) - 3600

    :ets.select_delete(@table, [
      {{:_, :"$1"}, [{:<, :"$1", cutoff}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
