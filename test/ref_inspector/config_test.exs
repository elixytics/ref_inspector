defmodule RefInspector.ConfigTest do
  use ExUnit.Case, async: false

  alias RefInspector.Config

  setup do
    app_path = Application.get_env(:ref_inspector, :database_path)

    on_exit fn ->
      Application.put_env(:ref_inspector, :database_path, app_path)
    end
  end


  test "application configuration" do
    path = "/configuration/by/application/configuration"
    url  = "http://some/host/database.yml"

    Application.put_env(:ref_inspector, :database_path, path)
    Application.put_env(:ref_inspector, :remote_url, url)

    assert path == Config.database_path
    assert url  == Config.yaml_url
  end


  test "system environment configuration" do
    path = "/configuration/by/system/environment"
    var  = "REF_INSPECTOR_CONFIG_TEST"

    Application.put_env(:ref_inspector, :database_path, { :system, var })
    System.put_env(var, path)

    assert path == Config.database_path
  end

  test "missing configuration" do
    Application.put_env(:ref_inspector, :database_path, nil)

    assert nil == Config.database_path
  end


  test "nested system environment access" do
    var = "REF_INSPECTOR_NESTED_CONFIG"
    val = "very-nested"

    System.put_env(var, val)

    Application.put_env(:ref_inspector, :test_only, deep: { :system, var })

    assert [ deep: val ] == Config.get(:test_only)

    Application.delete_env(:ref_inspector, :test_only)
  end
end