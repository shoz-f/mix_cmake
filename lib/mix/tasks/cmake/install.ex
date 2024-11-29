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

    cmake_args =
      Enum.flat_map(cmake_config, fn
        {:build_config, x}  -> ["--config", "#{x}"]
        _ -> []
      end)
      ++ Enum.flat_map(opts, fn
        {:verbose, true} -> ["--verbose"]
        {:strip, true}   -> ["--strip"]
        _ -> []
      end)
      ++ cmake_args

    cmake_env = Cmake.default_env()

    Cmake.cmake(build_dir, ["--install", "."] ++ cmake_args, cmake_env)
  end
end
