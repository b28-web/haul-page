defmodule Haul.Test.TimingFormatterTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @report_dir Path.join(File.cwd!(), "test/reports")
  @report_path Path.join(@report_dir, "timing.json")

  setup do
    # Clean up report file before each test
    File.rm(@report_path)
    on_exit(fn -> File.rm(@report_path) end)

    Application.put_env(:haul, :test_timing, %{
      compile_end: System.monotonic_time(:millisecond) - 5000
    })

    {:ok, pid} = GenServer.start_link(Haul.Test.TimingFormatter, [])
    %{pid: pid}
  end

  test "produces timing report with slowest tests", %{pid: pid} do
    GenServer.cast(pid, {:suite_started, %{}})

    send_test_finished(pid, %{
      module: MyApp.SlowTest,
      name: :"test slow operation",
      tags: %{file: "test/slow_test.exs", line: 10, async: false},
      time: 2_500_000
    })

    send_test_finished(pid, %{
      module: MyApp.FastTest,
      name: :"test fast operation",
      tags: %{file: "test/fast_test.exs", line: 5, async: true},
      time: 50_000
    })

    send_module_finished(pid, %{
      name: MyApp.SlowTest,
      file: "test/slow_test.exs",
      tests: [
        %{time: 2_500_000, tags: %{async: false}}
      ]
    })

    send_module_finished(pid, %{
      name: MyApp.FastTest,
      file: "test/fast_test.exs",
      tests: [
        %{time: 50_000, tags: %{async: true}}
      ]
    })

    output =
      capture_io(fn ->
        :erlang.group_leader(Process.group_leader(), pid)
        GenServer.cast(pid, {:suite_finished, %{run: 2_550_000, async: 50_000}})
        Process.sleep(200)
      end)

    assert output =~ "Test Timing Report"
    assert output =~ "Slowest Tests"
    assert output =~ "slow operation"
    assert output =~ "Slowest Files"
    assert output =~ "slow_test.exs"

    assert File.exists?(@report_path)
    json = Jason.decode!(File.read!(@report_path))

    assert length(json["slowest_tests"]) == 2
    assert length(json["all_tests"]) == 2
    assert hd(json["slowest_tests"])["time_ms"] == 2500
    assert json["sync_async"]["sync_files"] == 1
    assert json["sync_async"]["async_files"] == 1
  end

  test "computes sync vs async split correctly", %{pid: pid} do
    GenServer.cast(pid, {:suite_started, %{}})

    # 3 sync modules, 2 async modules
    for i <- 1..3 do
      send_module_finished(pid, %{
        name: :"Elixir.Sync#{i}",
        file: "test/sync#{i}_test.exs",
        tests: [%{time: 1_000_000, tags: %{async: false}}]
      })
    end

    for i <- 1..2 do
      send_module_finished(pid, %{
        name: :"Elixir.Async#{i}",
        file: "test/async#{i}_test.exs",
        tests: [%{time: 100_000, tags: %{async: true}}]
      })
    end

    output =
      capture_io(fn ->
        :erlang.group_leader(Process.group_leader(), pid)
        GenServer.cast(pid, {:suite_finished, %{run: 3_200_000, async: 200_000}})
        Process.sleep(200)
      end)

    assert output =~ "Sync files:  3"
    assert output =~ "Async files: 2"

    json = Jason.decode!(File.read!(@report_path))
    assert json["sync_async"]["sync_files"] == 3
    assert json["sync_async"]["async_files"] == 2
    assert json["sync_async"]["sync_total_ms"] == 3000
    assert json["sync_async"]["async_total_ms"] == 200
  end

  test "handles empty test suite", %{pid: pid} do
    GenServer.cast(pid, {:suite_started, %{}})

    output =
      capture_io(fn ->
        :erlang.group_leader(Process.group_leader(), pid)
        GenServer.cast(pid, {:suite_finished, %{run: 0, async: 0}})
        Process.sleep(200)
      end)

    assert output =~ "Test Timing Report"

    json = Jason.decode!(File.read!(@report_path))
    assert json["all_tests"] == []
    assert json["all_files"] == []
    assert json["sync_async"]["sync_files"] == 0
    assert json["sync_async"]["async_files"] == 0
  end

  test "ignores unknown events", %{pid: pid} do
    GenServer.cast(pid, {:unknown_event, %{}})
    GenServer.cast(pid, {:test_started, %{}})
    # Should not crash
    assert Process.alive?(pid)
  end

  ## Helpers

  defp send_test_finished(pid, attrs) do
    test = %ExUnit.Test{
      module: attrs.module,
      name: attrs.name,
      tags: attrs.tags,
      time: attrs.time,
      state: nil,
      logs: ""
    }

    GenServer.cast(pid, {:test_finished, test})
  end

  defp send_module_finished(pid, attrs) do
    tests =
      Enum.map(attrs.tests, fn t ->
        %ExUnit.Test{
          module: attrs.name,
          name: :test,
          tags: t.tags,
          time: t.time,
          state: nil,
          logs: ""
        }
      end)

    mod = %ExUnit.TestModule{
      name: attrs.name,
      file: attrs.file,
      tests: tests,
      state: nil
    }

    GenServer.cast(pid, {:module_finished, mod})
  end
end
