defmodule Mix.Tasks.Cmake.Build do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Build the CMake application"
  @moduledoc """
  Build the CMake application.

  $ mix cmake.build [opt] [build_dir] [++ CMake options]

  ## Command line options

  * `--parallel <n>`    - parallel jobs level
  * `--target <target>` - build target
  * `--clean-first`     - clean before build target
  * `--verbose`         - print process detail

  ## Configuration

  * `:build_dir`            - working directory
  * `:build_parallel_level` - parallel jobs level
  * `:build_config`         - build configuration (with Visual C++)
  * `:target <target>`      - build target if command line options has no `--target`.
  """

  @switches [
    parallel:    :integer,
    target:      :string,
    clean_first: :boolean,
    verbose:     :boolean
  ]
  @aliases [
    j: :parallel,
    t: :target,
    v: :verbose,
  ]

  @doc false
  def run(argv) do
    with {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, aliases: @aliases, strict: @switches),
      do: cmd(dirs, opts, cmake_args)
  end

  @doc false
  def cmd(), do: cmd([], [], [])
  @doc false
  def cmd(dirs, opts, cmake_args \\ []) do
    cmake_config = Cmake.get_config()

    [build_dir, _] = Cmake.get_dirs(dirs, cmake_config)

    cmake_args =
      Enum.flat_map(cmake_config, fn
        {:target, x}         -> unless(Keyword.has_key?(opts, :target), do: ["--target", "#{x}"], else: [])
        {:build_config, x}   -> ["--config", "#{x}"]
        _ -> []
      end)
      ++ Enum.flat_map(opts, fn
        {:verbose, true}     -> ["--verbose"]
        {:parallel, x}       -> ["--parallel", "#{x}"]
        {:target, x}         -> ["--target", "#{x}"]
        {:clean_first, true} -> ["--clean-first"]
        _ -> []
      end)
      ++ cmake_args

    cmake_env = Cmake.default_env()
      |> Cmake.add_env("CMAKE_BUILD_PARALLEL_LEVEL", cmake_config[:build_parallel_level])

    Cmake.cmake(build_dir, ["--build", "."] ++ cmake_args, cmake_env)
  end
end
