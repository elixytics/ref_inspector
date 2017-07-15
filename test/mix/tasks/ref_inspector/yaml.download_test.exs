defmodule Mix.Tasks.RefInspector.Yaml.DownloadTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.RefInspector.Yaml.Download


  @fixture_path Path.join([ __DIR__, "../../../fixtures" ]) |> Path.expand()
  @test_files   [ "referers_search.yml", "referers_social.yml" ]
  @test_path    Path.join([ __DIR__, "../../../downloads" ]) |> Path.expand()


  # compatibility hack for elixir 1.2.x
  if Version.match?(System.version, "~> 1.2.0") do
    def to_charlist(string), do: String.to_char_list(string)
  else
    @doc false
    def to_charlist(string), do: String.to_charlist(string)
  end


  setup_all do
    # setup internal testing webserver
    Application.ensure_all_started(:inets)

    httpd_opts         = [ port:          0,
                           server_name:   'ref_inspector_test',
                           server_root:   __MODULE__.to_charlist(@fixture_path),
                           document_root: __MODULE__.to_charlist(@fixture_path) ]
    { :ok, httpd_pid } = :inets.start(:httpd, httpd_opts)

    # configure app to use testing webserver
    remote_base = "http://localhost:#{ :httpd.info(httpd_pid)[:port] }"
    yaml_urls   = Application.get_env(:ref_inspector, :remote_urls)
    :ok         = Application.put_env(
      :ref_inspector,
      :remote_urls,
      Enum.map(@test_files, &( "#{remote_base}/#{&1}" ))
    )

    on_exit fn ->
      Application.put_env(:ref_inspector, :remote_urls, yaml_urls)
    end
  end


  test "aborted download" do
    Mix.shell(Mix.Shell.IO)

    console = capture_io fn ->
      Download.run([])
      IO.write("n")
    end

    assert String.contains?(console, "Download aborted")
  end

  test "confirmed download" do
    Mix.shell(Mix.Shell.IO)

    console = capture_io [capture_prompt: true], fn ->
      Download.run([])
    end

    assert String.contains?(console, "Download referers.yml? [Yn]")
  end

  test "forceable download" do
    Mix.shell(Mix.Shell.IO)

    orig_path  = Application.get_env(:ref_inspector, :database_path)
    test_files = Enum.map(@test_files, &( Path.join([ @test_path, &1 ]) ))

    Enum.each test_files, fn (test_file) ->
      if File.exists?(test_file) do
        test_file |> File.rm!
      end
    end

    console = capture_io fn ->
      Application.put_env(:ref_inspector, :database_path, @test_path)
      Download.run(["--force"])
      Application.put_env(:ref_inspector, :database_path, orig_path)
    end

    Enum.each test_files, fn (test_file) ->
      fixture_file = Path.join([ @fixture_path, Path.basename(test_file) ])

      assert File.exists?(test_file)
      assert String.contains?(console, test_file)
      assert File.stat!(test_file).size == File.stat!(fixture_file).size
    end
  end

  test "missing configuration" do
    Mix.shell(Mix.Shell.IO)

    orig_path = Application.get_env(:ref_inspector, :database_path)

    console = capture_io :stderr, fn ->
      Application.put_env(:ref_inspector, :database_path, nil)
      Download.run([])
      Application.put_env(:ref_inspector, :database_path, orig_path)
    end

    assert String.contains?(console, "not configured")
  end
end