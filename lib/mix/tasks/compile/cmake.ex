defmodule Mix.Tasks.Compile.Cmake do
  @moduledoc """
  Builds native source using CMake
  Runs `cmake` in the current project (followed by `make`) .

  This task runs `cmake` in the current project; any output coming from `cmake` is
  printed in real-time on stdout.

  ## Configuration

  This compiler can be configured through the return value of the `project/0`
  function in `mix.exs`; for example:
      def project() do
        [
          # ...
          compilers: [:cmake] ++ Mix.compilers,
          # ...
        ]
      end

   The following options are available:
    * `:cmake_env` - (map of binary to binary) it's a map of extra environment
      variables to be passed to `cmake`. You can also pass a function in here in
      case `make_env` needs access to things that are not available during project
      setup; the function should return a map of binary to binary. Many default
      environment variables are set, see section below

  ## Default environment variables
  There are also several default environment variables set:
    * `MIX_TARGET`
    * `MIX_ENV`
    * `MIX_BUILD_PATH` - same as `Mix.Project.build_path/0`
    * `MIX_APP_PATH` - same as `Mix.Project.app_path/0`
    * `MIX_COMPILE_PATH` - same as `Mix.Project.compile_path/0`
    * `MIX_CONSOLIDATION_PATH` - same as `Mix.Project.consolidation_path/0`
    * `MIX_DEPS_PATH` - same as `Mix.Project.deps_path/0`
    * `MIX_MANIFEST_PATH` - same as `Mix.Project.manifest_path/0`
    * `ERL_EI_LIBDIR`
    * `ERL_EI_INCLUDE_DIR`
    * `ERTS_INCLUDE_DIR`
    * `ERL_INTERFACE_LIB_DIR`
    * `ERL_INTERFACE_INCLUDE_DIR`
  These may also be overwritten with the `cmake_env` option.
  ## Compilation artifacts and working with priv directories
  Generally speaking, compilation artifacts are written to the `priv`
  directory, as that the only directory, besides `ebin`, which are
  available to Erlang/OTP applications.
  However, note that Mix projects supports the `:build_embedded`
  configuration, which controls if assets in the `_build` directory
  are symlinked (when `false`, the default) or copied (`true`).
  In order to support both options for `:build_embedded`, it is
  important to follow the given guidelines:
    * The "priv" directory must not exist in the source code
    * The Makefile should copy any artifact to `$MIX_APP_PATH/priv`
      or, even better, to `$MIX_APP_PATH/priv/$MIX_TARGET`
    * If there are static assets, the Makefile should copy them over
      from a directory at the project root (not named "priv")

  """
  use Mix.Task

  alias Mix.Tasks.Cmake

  def run(_argv) do
    cmake_config = Cmake.get_config()
    build_dir  = cmake_config[:build_dir]
    install_prefix = cmake_config[:install_prefix]

    cmake_env = Cmake.default_env()

    cond do
      !Cmake.build(build_dir, cmake_config[:build_opts], cmake_env) ->
        :error
      !Cmake.install(build_dir, install_prefix, cmake_config[:install_opts], cmake_env) ->
        :error
      true -> :ok
    end
  end

  @doc """
  Removes compiled artifacts.
  """
#  def clean() do
#    working_dir =
#      Mix.Project.config()
#      |> working_dir()
#
#    #cmd("make", ["clean"], working_dir)
#    :ok
#  end
end
