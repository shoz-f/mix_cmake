defmodule Mix.Tasks.Cmake.Install do
  use Mix.Task
  
  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Install the application to the project's priv"
  @moduledoc """
  Install the application to the project's priv.
  
  $ mix cmake.install [opt] [build_dir]
  
  ## Command line options

  * `--strip`    - remove debug info from executable
  * `--verbose`  - print process detail
  
  ## Configuration

  * `:build_dir` - working directory
  """
  
  @switches [
    strip:   :boolean,
    verbose: :boolean,
  ]

  def run(argv) do
    with {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: @switches),
      do: cmd(dirs, opts, cmake_args)
  end
  
  def cmd(dirs, opts, cmake_args \\ []) do
    cmake_config = Cmake.get_config()

    [build_dir, _] = Cmake.get_dirs(dirs, cmake_config)

    cmake_args = cmake_args
      |> Cmake.conj_front(opts[:verbose],  ["--verbose"])
      |> Cmake.conj_front(opts[:strip],    ["--strip"])

    cmake_env = Cmake.default_env()

    Cmake.cmake(build_dir, ["--install", "."] ++ cmake_args, cmake_env)
  end
end
