defmodule Mix.Tasks.Compile.Cmake do
  use Mix.Task.Compiler
  alias Mix.Tasks.Cmake

  @shortdoc "Runs `cmake` in the current project."
  @moduledoc """
  Runs `cmake` in the current project.

  It will skip execution cmake if the build directory exists.
  You can invoke `mix cmake --config` instead, if you want to cmake again.
  
  ## Configuration
  
  This compiler can be configured through the return value of the `project/0`
  function in `mix.exs`; for example:

  ```elixir
  def project() do
    [
      app: :myapp,
      deps: deps(),
      compilers: [:cmake] ++ Mix.compilers,
      
      cmake: [
        build_dir: :local,
        build_parallel_level: 4
      ]
    ]
  end
  ```
  
  * `:build_dir`  - working directory {:local, :global, any_directory}
  * `:source_dir` - source directory
  * `:generator`  - specify generator
  * `:build_parallel_level` - parallel jobs level

  ## Default environment variables

  There are several default environment variables set:

    * `MIX_TARGET` => env("MIX_TARGET", "host")
    * `MIX_ENV` => to_string(Mix.env())
    * `MIX_BUILD_PATH` => Mix.Project.build_path()
    * `MIX_APP_PATH` => Mix.Project.app_path()
    * `MIX_COMPILE_PATH` => Mix.Project.compile_path()
    * `MIX_CONSOLIDATION_PATH` => Mix.Project.consolidation_path()
    * `MIX_DEPS_PATH` => Mix.Project.deps_path()
    * `MIX_MANIFEST_PATH` => Mix.Project.manifest_path()
    * `ERL_EI_LIBDIR` => env("ERL_EI_LIBDIR", erl_ei_lib_dir)
    * `ERL_EI_INCLUDE_DIR` => env("ERL_EI_INCLUDE_DIR", erl_ei_include_dir)
    * `ERTS_INCLUDE_DIR` => env("ERTS_INCLUDE_DIR", erts_include_dir)
    * `ERL_INTERFACE_LIB_DIR` => env("ERL_INTERFACE_LIB_DIR", erl_ei_lib_dir)
    * `ERL_INTERFACE_INCLUDE_DIR` => env("ERL_INTERFACE_INCLUDE_DIR", erl_ei_include_dir)

  """

  @doc false
  def run(_args) do
    cond do
      check_env?("CMAKE_SKIP") ->
        :ok
      (already_built?() || Cmake.Config.cmd() && Cmake.Build.cmd()) && Cmake.Install.cmd() ->
        :ok
      true ->
        {:error, []}
    end
  end

  defp already_built?() do
    Cmake.get_config()[:build_dir]
    |> Cmake.build_dir_exists?()
  end

  defp check_env?(name), do:
    System.get_env(name, "NO") |> String.upcase() |> Kernel.in(["YES", "OK", "TRUE"])

  @doc false
  def clean() do
    Cmake.Clean.cmd()
  end
end
