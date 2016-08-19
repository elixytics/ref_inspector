defmodule Mix.RefInspector.Verify.Fixture do
  @moduledoc """
  Utility module to bundle/download the verification fixture.
  """

  alias Mix.RefInspector.Download


  @local  "referer-tests.json"
  @remote "https://raw.githubusercontent.com/snowplow/referer-parser/master/resources/referer-tests.json"


  def download() do
    Mix.shell.info "Download path: #{ download_path() }"

    setup()
    download_fixture()

    Mix.shell.info "Download complete!"
    :ok
  end

  def download_fixture() do
    Mix.shell.info ".. downloading: #{ @local }"

    { :ok, content } = Download.read_remote(@remote)

    File.write! local_file(), content
  end

  def download_path, do: Path.join(__DIR__, "../../../../database") |> Path.expand()
  def local_file,    do: Path.join([ download_path(), @local ])

  def setup() do
    File.mkdir_p! download_path()
  end
end
