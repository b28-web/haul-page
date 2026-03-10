defmodule Mix.Tasks.Haul.TestPyramidTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Haul.TestPyramid

  @moduletag :tmp_dir

  describe "classify/1" do
    test "detects Tier 1 (ExUnit.Case)", %{tmp_dir: dir} do
      path = write_test_file(dir, "unit_test.exs", "use ExUnit.Case, async: true")
      assert TestPyramid.classify(path) == :unit
    end

    test "detects Tier 2 (DataCase)", %{tmp_dir: dir} do
      path = write_test_file(dir, "resource_test.exs", "use Haul.DataCase, async: false")
      assert TestPyramid.classify(path) == :resource
    end

    test "detects Tier 3 (ConnCase)", %{tmp_dir: dir} do
      path = write_test_file(dir, "integration_test.exs", "use HaulWeb.ConnCase, async: false")
      assert TestPyramid.classify(path) == :integration
    end

    test "returns :unknown for unrecognized files", %{tmp_dir: dir} do
      path = write_test_file(dir, "weird_test.exs", "use SomeOtherCase")
      assert TestPyramid.classify(path) == :unknown
    end
  end

  describe "count_tests/1" do
    test "counts test declarations", %{tmp_dir: dir} do
      content = """
      defmodule FooTest do
        use ExUnit.Case, async: true

        test "first thing" do
          assert true
        end

        test "second thing" do
          assert true
        end
      end
      """

      path = Path.join(dir, "foo_test.exs")
      File.write!(path, content)
      assert TestPyramid.count_tests(path) == 2
    end

    test "ignores non-test lines", %{tmp_dir: dir} do
      content = """
      defmodule FooTest do
        use ExUnit.Case, async: true

        # test "commented out" do
        describe "a group" do
          test "only this one" do
            assert true
          end
        end
      end
      """

      path = Path.join(dir, "bar_test.exs")
      File.write!(path, content)
      assert TestPyramid.count_tests(path) == 1
    end
  end

  describe "scan_files/1" do
    test "scans directory and classifies files", %{tmp_dir: dir} do
      write_test_file(dir, "a_test.exs", "use ExUnit.Case, async: true", 3)
      write_test_file(dir, "b_test.exs", "use Haul.DataCase", 2)

      results = TestPyramid.scan_files(dir)

      assert length(results) == 2

      unit = Enum.find(results, &(elem(&1, 1) == :unit))
      assert elem(unit, 2) == 3

      resource = Enum.find(results, &(elem(&1, 1) == :resource))
      assert elem(resource, 2) == 2
    end

    test "finds files in subdirectories", %{tmp_dir: dir} do
      sub = Path.join(dir, "sub")
      File.mkdir_p!(sub)
      write_test_file(sub, "deep_test.exs", "use HaulWeb.ConnCase", 1)

      results = TestPyramid.scan_files(dir)
      assert length(results) == 1
      assert elem(hd(results), 1) == :integration
    end
  end

  describe "format_report/1" do
    test "includes all tier lines and totals" do
      results = [
        {"a_test.exs", :unit, 40},
        {"b_test.exs", :resource, 30},
        {"c_test.exs", :integration, 30}
      ]

      report = TestPyramid.format_report(results)

      assert report =~ "Test Pyramid Report"
      assert report =~ "Tier 1 (Unit):"
      assert report =~ "Tier 2 (Resource):"
      assert report =~ "Tier 3 (Integration):"
      assert report =~ "Total: 100 tests in 3 files"
      assert report =~ "Target: 40% / 30% / 30%"
      assert report =~ "█"
    end

    test "handles empty results" do
      report = TestPyramid.format_report([])

      assert report =~ "Total: 0 tests in 0 files"
      assert report =~ "Tier 1 (Unit):"
    end
  end

  defp write_test_file(dir, name, use_line, test_count \\ 1) do
    tests =
      for i <- 1..test_count do
        """
          test "test #{i}" do
            assert true
          end
        """
      end
      |> Enum.join("\n")

    content = """
    defmodule #{String.replace(name, ".exs", "") |> Macro.camelize()}Test do
      #{use_line}

    #{tests}
    end
    """

    path = Path.join(dir, name)
    File.write!(path, content)
    path
  end
end
