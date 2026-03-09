defmodule Haul.Test.TimingFormatter do
  @moduledoc """
  ExUnit formatter that captures per-test and per-file timing data.

  Activated via: HAUL_TEST_TIMING=1 mix test

  Produces:
  - Human-readable summary to stdout
  - Machine-parseable JSON to test/reports/timing.json
  """

  use GenServer

  ## GenServer callbacks (ExUnit formatter protocol)

  def init(_opts) do
    timing_config = Application.get_env(:haul, :test_timing, %{})

    {:ok,
     %{
       compile_end_ms: Map.get(timing_config, :compile_end),
       suite_start_ms: nil,
       tests: [],
       modules: []
     }}
  end

  def handle_cast({:suite_started, _opts}, state) do
    {:noreply, %{state | suite_start_ms: System.monotonic_time(:millisecond)}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, state) do
    entry = %{
      module: inspect(test.module),
      name: to_string(test.name),
      file: test.tags[:file],
      line: test.tags[:line],
      time_us: test.time,
      async: test.tags[:async] || false
    }

    {:noreply, %{state | tests: [entry | state.tests]}}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{} = mod}, state) do
    total_time = Enum.reduce(mod.tests, 0, fn t, acc -> acc + t.time end)

    async =
      case mod.tests do
        [first | _] -> first.tags[:async] || false
        [] -> false
      end

    entry = %{
      name: inspect(mod.name),
      file: mod.file,
      test_count: length(mod.tests),
      total_time_us: total_time,
      async: async
    }

    {:noreply, %{state | modules: [entry | state.modules]}}
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    suite_end_ms = System.monotonic_time(:millisecond)
    report = build_report(state, suite_end_ms)
    print_summary(report)
    write_json(report)
    {:noreply, state}
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end

  ## Report building

  defp build_report(state, suite_end_ms) do
    tests_sorted = Enum.sort_by(state.tests, & &1.time_us, :desc)
    modules_sorted = Enum.sort_by(state.modules, & &1.total_time_us, :desc)

    wall_clock_ms =
      if state.compile_end_ms, do: suite_end_ms - state.compile_end_ms, else: nil

    setup_ms =
      if state.compile_end_ms && state.suite_start_ms,
        do: state.suite_start_ms - state.compile_end_ms,
        else: nil

    test_run_ms =
      if state.suite_start_ms, do: suite_end_ms - state.suite_start_ms, else: nil

    {sync_modules, async_modules} = Enum.split_with(modules_sorted, &(!&1.async))

    sync_total_us = Enum.reduce(sync_modules, 0, fn m, acc -> acc + m.total_time_us end)
    async_total_us = Enum.reduce(async_modules, 0, fn m, acc -> acc + m.total_time_us end)

    %{
      wall_clock_ms: wall_clock_ms,
      setup_ms: setup_ms,
      test_run_ms: test_run_ms,
      sync_async: %{
        sync_files: length(sync_modules),
        sync_total_ms: div(sync_total_us, 1000),
        async_files: length(async_modules),
        async_total_ms: div(async_total_us, 1000)
      },
      slowest_tests: Enum.take(tests_sorted, 20),
      slowest_files: Enum.take(modules_sorted, 20),
      all_tests: tests_sorted,
      all_files: modules_sorted
    }
  end

  ## Output

  defp print_summary(report) do
    IO.puts("\n\n#{String.duplicate("=", 60)}")
    IO.puts("  Test Timing Report")
    IO.puts(String.duplicate("=", 60))

    if report.setup_ms do
      IO.puts("\n  Setup/compile overhead: #{format_ms(report.setup_ms)}")
    end

    if report.test_run_ms do
      IO.puts("  Test execution:         #{format_ms(report.test_run_ms)}")
    end

    if report.wall_clock_ms do
      IO.puts("  Total wall-clock:       #{format_ms(report.wall_clock_ms)}")
    end

    sa = report.sync_async

    IO.puts("\n#{String.duplicate("-", 40)}")
    IO.puts("  Sync vs Async")
    IO.puts(String.duplicate("-", 40))
    IO.puts("  Sync files:  #{sa.sync_files} (#{format_ms(sa.sync_total_ms)})")
    IO.puts("  Async files: #{sa.async_files} (#{format_ms(sa.async_total_ms)})")

    IO.puts("\n#{String.duplicate("-", 40)}")
    IO.puts("  Top 20 Slowest Tests")
    IO.puts(String.duplicate("-", 40))

    report.slowest_tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, i} ->
      ms = div(test.time_us, 1000)
      pad = String.pad_leading("#{i}.", 4)
      file = Path.relative_to_cwd(test.file || "unknown")

      IO.puts(
        "  #{pad} #{String.pad_leading(format_ms(ms), 10)}  #{file}:#{test.line} — #{test.name}"
      )
    end)

    IO.puts("\n#{String.duplicate("-", 40)}")
    IO.puts("  Top 20 Slowest Files")
    IO.puts(String.duplicate("-", 40))

    report.slowest_files
    |> Enum.with_index(1)
    |> Enum.each(fn {mod, i} ->
      ms = div(mod.total_time_us, 1000)
      avg = if mod.test_count > 0, do: div(ms, mod.test_count), else: 0
      pad = String.pad_leading("#{i}.", 4)
      file = Path.relative_to_cwd(mod.file || "unknown")

      IO.puts(
        "  #{pad} #{String.pad_leading(format_ms(ms), 10)}  #{file} (#{mod.test_count} tests, avg #{format_ms(avg)})"
      )
    end)

    IO.puts("\n#{String.duplicate("=", 60)}\n")
  end

  defp write_json(report) do
    dir = Path.join(File.cwd!(), "test/reports")
    File.mkdir_p!(dir)
    path = Path.join(dir, "timing.json")

    json_data = %{
      wall_clock_ms: report.wall_clock_ms,
      setup_ms: report.setup_ms,
      test_run_ms: report.test_run_ms,
      sync_async: report.sync_async,
      slowest_tests:
        Enum.map(report.slowest_tests, fn t ->
          %{
            module: t.module,
            name: t.name,
            file: t.file,
            line: t.line,
            time_ms: div(t.time_us, 1000),
            async: t.async
          }
        end),
      slowest_files:
        Enum.map(report.slowest_files, fn m ->
          %{
            name: m.name,
            file: m.file,
            test_count: m.test_count,
            total_time_ms: div(m.total_time_us, 1000),
            avg_time_ms:
              if(m.test_count > 0, do: div(div(m.total_time_us, 1000), m.test_count), else: 0),
            async: m.async
          }
        end),
      all_tests:
        Enum.map(report.all_tests, fn t ->
          %{
            module: t.module,
            name: t.name,
            file: t.file,
            line: t.line,
            time_ms: div(t.time_us, 1000),
            async: t.async
          }
        end),
      all_files:
        Enum.map(report.all_files, fn m ->
          %{
            name: m.name,
            file: m.file,
            test_count: m.test_count,
            total_time_ms: div(m.total_time_us, 1000),
            async: m.async
          }
        end)
    }

    File.write!(path, Jason.encode!(json_data, pretty: true))
    IO.puts("  Timing report written to: #{path}")
  end

  defp format_ms(ms) when is_integer(ms) and ms >= 1000 do
    seconds = div(ms, 1000)
    remainder = rem(ms, 1000)
    "#{seconds},#{String.pad_leading("#{remainder}", 3, "0")}ms"
  end

  defp format_ms(ms) when is_integer(ms), do: "#{ms}ms"
  defp format_ms(_), do: "N/A"
end
