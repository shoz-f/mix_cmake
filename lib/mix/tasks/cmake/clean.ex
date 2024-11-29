defmodule Mix.Tasks.Cmake.Clean do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Clean outputs of Cmake"
  @moduledoc """
  Clean outputs of Cmake.

  $ mix cmake.clean [opt]

  ## Command line options

  * `--all`     - remove cmake build directory.
  * `--verbose` - print process detail
  """

  @switches [
    all:     :boolean,
    verbose: :boolean
  ]

  @doc false
  def run(argv) do
    with {:ok, opts, dirs, _cmake_args} <- Cmake.parse_argv(argv, strict: @switches),
      do: cmd(dirs, opts, [])
  end

  @doc false
  def cmd(), do: cmd([], [], [])
  @doc false
  def cmd(dirs, opts, _cmake_args \\ []) do
    cmake_config = Cmake.get_config()

    [build_dir, _] = Cmake.get_dirs(dirs, cmake_config)

    if opts[:all] do
      Cmake.remove_build(build_dir)
    else
      cmake_args =
        Enum.flat_map(opts, fn
          {:verbose, true} -> ["--verbose"]
          _ -> []
        end)
        ++ ["--target", "clean"]

      cmake_env = Cmake.default_env()

      Cmake.cmake(build_dir, ["--build", "."]  ++ cmake_args, cmake_env)
    end
  end
end
