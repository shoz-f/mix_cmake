defmodule  Mix.Tasks.Cmake.Config do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Generate build scripts based on the CMakeLists.txt"
  @moduledoc """
  Generate build scripts based on the 'CMakeLists.txt'.
  
  $ mix cmake.config [opt] [build_dir] [source_dir] [++ CMake options]
  
  ## Command line options
  
  * `--generator` - specify generator
  
  ## Configuration

  * `:build_dir`  - working directory
  * `:source_dir` - source directory
  * `:generator`  - specify generator
  """
  @switches [
    generator: :string,
    platform:  :string,
  ]
  
  @doc false
  def run(argv) do
    with {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: @switches),
      do: cmd(dirs, opts, cmake_args)
  end
  
  @doc false
  def cmd(), do: cmd([], [], [])
  @doc false
  def cmd(dirs, opts, cmake_args \\ []) do
    cmake_config = Cmake.get_config()

    [build_dir, source_dir] = Cmake.get_dirs(dirs, cmake_config)

    cmake_args = cmake_args
      |> Cmake.conj_front(opts[:generator], ["-G", "#{opts[:generator]}"])
      |> Cmake.conj_front(opts[:platform], ["-A", "#{opts[:platform]}"])
      |> Cmake.conj_front(cmake_config[:platform], ["-A", "#{cmake_config[:platform]}"])

    cmake_env = Cmake.default_env()
      |> Cmake.add_env("CMAKE_GENERATOR", cmake_config[:generator])

    # construct cmake args
    cmake_args = if build_dir == :global,
      do:   ["-UCMAKE_HOME_DIRECTORY", "-UCONFU_DEPENDENCIES_SOURCE_DIR" | cmake_args], # add options to remove some cache entries
      else: cmake_args

    # invoke cmake
    Cmake.cmake(build_dir, cmake_args ++ [Path.expand(source_dir)], cmake_env)
  end
end
