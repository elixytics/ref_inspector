defmodule RefInspector.Database.ReloadTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @fixture_search "referers_search.yml"
  @fixture_social "referers_social.yml"

  setup do
    app_files = Application.get_env(:ref_inspector, :database_files)
    app_path = Application.get_env(:ref_inspector, :database_path)

    on_exit(fn ->
      Application.put_env(:ref_inspector, :database_files, app_files)
      Application.put_env(:ref_inspector, :database_path, app_path)
    end)
  end

  test "reloading databases" do
    Application.put_env(:ref_inspector, :database_files, [@fixture_search])
    RefInspector.reload(async: false)

    assert RefInspector.ready?()
    assert RefInspector.parse("http://www.google.com/test").source == "Google"
    assert RefInspector.parse("http://twitter.com/test").source == :unknown

    Application.put_env(:ref_inspector, :database_files, [@fixture_social])
    RefInspector.reload(async: false)

    assert RefInspector.ready?()
    assert RefInspector.parse("http://www.google.com/test").source == :unknown
    assert RefInspector.parse("http://twitter.com/test").source == "Twitter"
  end

  test "warns about missing files configuration (sync reload)" do
    Application.put_env(:ref_inspector, :database_files, [])

    log =
      capture_log(fn ->
        RefInspector.reload(async: false)
      end)

    assert log =~ ~r/no database files/i
    refute RefInspector.ready?()
  end

  test "warns about missing files configuration (async reload)" do
    Application.put_env(:ref_inspector, :database_files, [])

    log =
      capture_log(fn ->
        RefInspector.reload()

        :ref_inspector_default
        |> Process.whereis()
        |> :sys.get_state()
      end)

    assert log =~ ~r/no database files/i
    refute RefInspector.ready?()
  end
end
