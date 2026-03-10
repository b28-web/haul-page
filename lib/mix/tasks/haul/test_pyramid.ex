defmodule Mix.Tasks.Haul.TestPyramid do
  @moduledoc "Report the test pyramid shape — tier distribution across test files."
  @shortdoc "Report the test pyramid shape"

  use Mix.Task

  @tiers [
    {:unit, "Tier 1 (Unit)", ~r/use ExUnit\.Case/},
    {:resource, "Tier 2 (Resource)", ~r/use Haul\.DataCase/},
    {:integration, "Tier 3 (Integration)", ~r/use HaulWeb\.ConnCase/}
  ]

  @max_bar 20
  @target "Target: 40% / 30% / 30%"

  @impl Mix.Task
  def run(_args) do
    "test"
    |> scan_files()
    |> format_report()
    |> Mix.shell().info()
  end

  @doc "Scan test files in `dir` and return `[{path, tier, test_count}]`."
  def scan_files(dir) do
    Path.wildcard(Path.join(dir, "**/*_test.exs"))
    |> Enum.map(fn path ->
      {path, classify(path), count_tests(path)}
    end)
  end

  @doc "Classify a test file by its `use` declaration."
  def classify(path) do
    head = path |> File.stream!() |> Enum.take(20) |> Enum.join()

    Enum.find_value(@tiers, :unknown, fn {tier, _label, pattern} ->
      if Regex.match?(pattern, head), do: tier
    end)
  end

  @doc "Count `test \"...\"` declarations in a file."
  def count_tests(path) do
    path
    |> File.stream!()
    |> Enum.count(&Regex.match?(~r/^\s+test\s+"/, &1))
  end

  @doc "Format scan results into the pyramid report string."
  def format_report(results) do
    grouped =
      Enum.group_by(results, &elem(&1, 1))

    total_tests = results |> Enum.map(&elem(&1, 2)) |> Enum.sum()
    total_files = length(results)

    lines =
      for {tier, _label, _pattern} <- @tiers do
        entries = Map.get(grouped, tier, [])
        tests = entries |> Enum.map(&elem(&1, 2)) |> Enum.sum()
        files = length(entries)
        pct = if total_tests > 0, do: round(tests / total_tests * 100), else: 0

        {tier, tests, files, pct}
      end

    tier_lines =
      Enum.map(lines, fn {tier, tests, files, pct} ->
        label = tier_label(tier)
        bar = bar(pct)

        "  #{String.pad_trailing(label, 22)} #{pad_num(tests)} tests in #{pad_num(files)} files   (#{String.pad_leading("#{pct}", 2)}%)  #{bar}"
      end)

    separator = "  ───────────────────"

    [
      "",
      "  Test Pyramid Report",
      separator,
      tier_lines,
      separator,
      "  Total: #{total_tests} tests in #{total_files} files",
      "  #{@target}",
      ""
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp tier_label(:unit), do: "Tier 1 (Unit):"
  defp tier_label(:resource), do: "Tier 2 (Resource):"
  defp tier_label(:integration), do: "Tier 3 (Integration):"
  defp tier_label(_), do: "Unknown:"

  defp bar(pct) do
    width = round(pct / 100 * @max_bar)
    String.duplicate("█", width)
  end

  defp pad_num(n), do: String.pad_leading("#{n}", 4)
end
