defmodule Mix.Tasks.Cmake.Build do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Build the CMake application"
  @moduledoc """
  Build the CMake application.
  
  $ mix cmake.build [opt] [build_dir] [++ CMake options]
  
  ## Command line options
  
  * `--parallel` - parallel jobs level
  * `--target`   - build target
  * `--clean`     - clean before build target
  * `--verbose`  - print process detail
  
  ## Configuration

  * `:build_dir`            - working directory
  * `:build_parallel_level` - parallel jobs level
  """

  @switches [
    parallel: :integer,
    target:   :string,
    clean:    :boolean,
    verbose:  :boolean
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

    [build_dir, _] = Cmake.get_dirs(dirs, cmake_config)

    cmake_args = cmake_args
      |> Cmake.conj_front(opts[:verbose],  ["--verbose"])
      |> Cmake.conj_front(opts[:parallel], ["--parallel", "#{opts[:parallel]}"])
      |> Cmake.conj_front(opts[:target],   ["--target", "#{opts[:target]}"])
      |> Cmake.conj_front(opts[:clean],    ["--clean-first"])

    cmake_env = Cmake.default_env()
      |> Cmake.add_env("CMAKE_BUILD_PARALLEL_LEVEL", cmake_config[:build_parallel_level])

    Cmake.cmake(build_dir, ["--build", "."] ++ cmake_args, cmake_env)
  end
end
