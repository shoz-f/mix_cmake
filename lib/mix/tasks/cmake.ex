defmodule Mix.Tasks.Cmake do
  use Mix.Task
  alias Mix.Tasks.Cmake

  defmacro conj_front(list, val, form) do
    quote do
      if unquote(val), do: unquote(form) ++ unquote(list), else: unquote(list)
    end
  end

  @shortdoc "Generate CMake buiid scripts and then build/install the application"
  @moduledoc """
  Generate CMake buiid scripts and then build/install the application.
  
    mix cmake.all
  
  ## Command line options
  * `--config` - generate build script
  
  ## Configuration

  * `:build_dir` -
  * `:source_dir` - specify project directory.
  * `:generator` -
  * `:build_parallel_level` -
  """

  @switches [
    config: :boolean
  ]

  def run(argv) do
    with\
      {:ok, opts, _dirs, _cmake_args} <- Cmake.parse_argv(argv, strict: @switches)
    do
      if opts[:config], do: Mix.Task.run("cmake.config", argv)

      Mix.Task.run("cmake.build", argv)
      Mix.Task.run("cmake.install", argv)
    end
  end


  def config(build_dir, source_dir, args \\ [], env \\ %{}) do
    # convert dir name to absolute path
    build_path  = build_path(build_dir)
    source_path = Path.expand(source_dir)

    # make build directory
    File.mkdir_p(build_path)

    # construct cmake args
    args = if build_dir == :global,
      do:   ["-UCMAKE_HOME_DIRECTORY", "-UCONFU_DEPENDENCIES_SOURCE_DIR" | args], # add options to remove some cache entries
      else: args

    # invoke cmake
    cmake(build_path, args ++ [source_path], env)
  end

  def build(build_dir, args \\ [], env \\ %{}),
    do: cmake(build_path(build_dir), ["--build", "."] ++ args, env)

  def install(build_dir, args \\ [], env \\ %{}),
    do: cmake(build_path(build_dir), ["--install", "."] ++ args, env)

  defp cmake(build_path, args, env) do
    opts = [
      cd: build_path,
      env: env,
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    if Map.has_key?(env, "VERBOSE") do
    IO.inspect([args: args, opts: opts])
    end

    {%IO.Stream{}, status} = System.cmd("cmake", args, opts)
    (status == 0)
  end

  defp build_path(:local) do
    Mix.Project.build_path()
    |> Path.join(".cmake_build")
  end

  defp build_path(:global) do
    System.user_home
    |> Path.absname()
    |> Path.join(".#{app_name()}")
  end

  defp build_path(dir), do: Path.expand(dir)

  @doc "get application name"
  def app_name(), do: Atom.to_string(Mix.Project.config[:app])

  @doc "get :cmake configuration from Mix.exs"
  def get_config() do
    Keyword.get(Mix.Project.config(), :cmake, [])
    # default setting if it has no configuration
    |> Keyword.put_new(:build_dir, :priv)
    |> Keyword.put_new(:source_dir, File.cwd!)
    |> Keyword.put_new(:config_opts, [])
    |> Keyword.put_new(:build_opts, [])
  end


  @doc """
  Returns a map of default environment variables
  """
  def default_env() do
    root_dir = :code.root_dir()
    erl_interface_dir = Path.join(root_dir, "usr")
    erts_dir = Path.join(root_dir, "erts-#{:erlang.system_info(:version)}")
    erts_include_dir = Path.join(erts_dir, "include")
    erl_ei_lib_dir = Path.join(erl_interface_dir, "lib")
    erl_ei_include_dir = Path.join(erl_interface_dir, "include")

    %{
      # Don't use Mix.target/0 here for backwards compatability
      "MIX_TARGET" => env("MIX_TARGET", "host"),
      "MIX_ENV" => to_string(Mix.env()),
      "MIX_BUILD_PATH" => Mix.Project.build_path(),
      "MIX_APP_PATH" => Mix.Project.app_path(),
      "MIX_COMPILE_PATH" => Mix.Project.compile_path(),
      "MIX_CONSOLIDATION_PATH" => Mix.Project.consolidation_path(),
      "MIX_DEPS_PATH" => Mix.Project.deps_path(),
      "MIX_MANIFEST_PATH" => Mix.Project.manifest_path(),

      # Rebar naming
      "ERL_EI_LIBDIR" => env("ERL_EI_LIBDIR", erl_ei_lib_dir),
      "ERL_EI_INCLUDE_DIR" => env("ERL_EI_INCLUDE_DIR", erl_ei_include_dir),

      # erlang.mk naming
      "ERTS_INCLUDE_DIR" => env("ERTS_INCLUDE_DIR", erts_include_dir),
      "ERL_INTERFACE_LIB_DIR" => env("ERL_INTERFACE_LIB_DIR", erl_ei_lib_dir),
      "ERL_INTERFACE_INCLUDE_DIR" => env("ERL_INTERFACE_INCLUDE_DIR", erl_ei_include_dir)
    }
  end

  defp env(var, default) do
    System.get_env(var) || default
  end

  def add_env(env, _name, nil),                  do: env
  def add_env(env, name, true),                  do: Map.put(env, name, "true")
  def add_env(env, name, i) when is_integer(i), do: Map.put(env, name, Integer.to_string(i))
  def add_env(env, name, f) when is_float(f),   do: Map.put(env, name, Float.to_string(f))
  def add_env(env, name, a) when is_atom(a),    do: Map.put(env, name, Atom.to_string(a))
  def add_env(env, name, s),                     do: Map.put(env, name, s)

  @doc """
  parse command line arguments.
  """
  def parse_argv(argv, config \\ []) when is_list(argv) and is_list(config) do
    do_parse(argv, config, [], [])
  end

  defp do_parse([], _config, opts, args) do
    {:ok, opts, Enum.reverse(args), []}
  end

  defp do_parse(argv, config, opts, args) do
    case next(argv, config) do
      {:second, rest} ->  # start of 2nd args
        {:ok, opts, Enum.reverse(args), rest}
      {:ok, option, value, rest} ->
        do_parse(rest, config, [{option, value}|Keyword.delete(opts, option)], args)
      {:invalid, key, value, _rest} ->
        {:invalid, key, value}
      {:undefined, _key, _value, rest} ->
        do_parse(rest, config, opts, args)
      {:error, [<<":",atom::binary>>|rest]} -> # atom formed
        do_parse(rest, config, opts, [String.to_atom(atom)|args])
      {:error, [arg|rest]} ->
        do_parse(rest, config, opts, [arg|args])
    end
  end

  def next(argv, opts \\ [])
  def next(["++"|rest], _opts), do: {:second, rest}
  def next(["--"|rest], _opts), do: {:second, rest}
  defdelegate next(argv, opts), to: OptionParser
end



defmodule Mix.Tasks.Cmake.Debug do
  use Mix.Task

  alias Mix.Tasks.Cmake
  require Cmake

  @switches [
    generator: :string,
    verbose:   :boolean
  ]

  def run(argv) do
    {:ok, opts, params, cmake_args} = Cmake.parse_argv(argv, strict: @switches)
    IO.inspect(argv)
    IO.inspect(opts)
    IO.inspect(params)
    IO.inspect(cmake_args)
    
    cmake_config = Cmake.get_config()

    cmake_env = Cmake.default_env()
      |> Cmake.add_env("CMAKE_GENERATOR", cmake_config[:generator])
      |> Cmake.add_env("CMAKE_GENERATOR", opts[:generator])
      |> Cmake.add_env("VERBOSE", opts[:verbose])
      |> IO.inspect

    cmake_args = cmake_args
      |> Cmake.conj_front(opts[:generator], ["-G", "#{opts[:generator]}"])
      |> IO.inspect
  end
end
