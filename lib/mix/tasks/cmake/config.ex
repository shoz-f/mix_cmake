defmodule  Mix.Tasks.Cmake.Config do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Generate build scripts based on the CMakeLists.txt"
  @moduledoc """
  Generate build scripts based on the 'CMakeLists.txt'.

  $ mix cmake.config [opt] [build_dir] [source_dir] [++ CMake options]

  ## Command line options

  * `--generator`              - specify generator.
  * `--define "<var>=<value>"` - create or update a CMake CACHE entry.
  * `--undef <var>`            - remove the entry from CMake CACHE.
  * `--trace`                  - put cmake in trace mode.
  * `--recache`                - remove CMakeCache.txt.

  ## Configuration

  * `:build_dir`  - working directory
  * `:source_dir` - source directory
  * `:generator`  - specify generator
  """
  @switches [
    generator: :string,
    platform:  :string,
    define:    :keep,
    undef:     :keep,
    trace:     :boolean,
    preset:    :string,
    recache:   :boolean,
  ]
  @aliases [
    D: :define,
    U: :undef,
  ]

  @doc false
  def run(argv) do
    with {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, aliases: @aliases, strict: @switches),
      do: cmd(dirs, opts, cmake_args)
  end

  @doc false
  def cmd(), do: cmd([], [], [])
  @spec cmd(list(), nil | maybe_improper_list() | map()) :: boolean()
  @doc false
  def cmd(dirs, opts, cmake_args \\ []) do
    cmake_config = Cmake.get_config()

    [build_dir, source_dir] = Cmake.get_dirs(dirs, cmake_config)

    cmake_args =
      Enum.flat_map(cmake_config, fn
        {:platform, x}  -> ["-A", "#{x}"]
        _ -> []
      end)
      ++ Enum.flat_map(opts, fn
        {:generator, x} -> ["-G", "#{x}"]
        {:platform, x}  -> ["-A", "#{x}"]
        {:trace, true}  -> ["--trace"]
        {:preset, x}    -> ["--preset", "#{x}"]
        {:define, x}    -> ["-D", "#{x}"]
        {:undef, x}     -> ["-U", "#{x}"]
        _ -> []
      end)
      ++ cmake_args

    cmake_env = Cmake.default_env()
      |> Cmake.add_env("CMAKE_GENERATOR", cmake_config[:generator])

    # construct cmake args
    cmake_args = if build_dir == :global,
      do:   ["-UCMAKE_HOME_DIRECTORY", "-UCONFU_DEPENDENCIES_SOURCE_DIR" | cmake_args], # add options to remove some cache entries
      else: cmake_args

    # invoke cmake
    if opts[:recache] do
      Cmake.remove_cache(build_dir)
    end

    Cmake.cmake(build_dir, cmake_args ++ [Path.expand(source_dir)], cmake_env)
  end
end
