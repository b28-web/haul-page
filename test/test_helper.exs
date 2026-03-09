if System.get_env("HAUL_TEST_TIMING") == "1" do
  Application.put_env(:haul, :test_timing, %{
    compile_end: System.monotonic_time(:millisecond)
  })

  ExUnit.start(
    exclude: [:baml_live],
    formatters: [ExUnit.CLIFormatter, Haul.Test.TimingFormatter]
  )
else
  ExUnit.start(exclude: [:baml_live])
end

Ecto.Adapters.SQL.Sandbox.mode(Haul.Repo, :manual)
