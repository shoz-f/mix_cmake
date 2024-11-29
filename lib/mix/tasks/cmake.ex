defmodule Mix.Tasks.Cmake do
  use Mix.Task
  alias Mix.Tasks.Cmake

  @shortdoc "Generate CMake buiid scripts and then build/install the application"
  @moduledoc """
  Generate CMake buiid scripts and then build/install the application.

  $ mix cmake [opt] [build_dir] [source_dir]

  ## Command line options

  * `--config`      - generate build script
  * `--generator`   - specify generator
  * `--parallel`    - parallel jobs level
  * `--target`      - build target
  * `--clean-first` - clean before build target
  * `--strip`       - remove debug info from executable
  * `--verbose`     - print process detail

  ## Configuration
  Add following configurations at project/1 in your mix.exs if you need.

  ```elixir
  def project do
    [
      cmake: [...]
    ]
  end
  ```

  * `:build_dir`  - working directory {:local, :global, any_directory}
  * `:source_dir` - source directory
  * `:generator`  - specify generator
  * `:build_parallel_level` - parallel jobs level
  """

  @switches [
    config:      :boolean,
    generator:   :string,
    platform:    :string,
    define:      :keep,
    undef:       :keep,
    trace:       :boolean,
    recache:     :boolean,

    parallel:    :integer,
    target:      :string,
    clean_first: :boolean,

    strip:       :boolean,
    verbose:     :boolean,
  ]

  def run(argv) do
    with\
      {:ok, opts, dirs, _cmake_args} <- parse_argv(argv, strict: @switches)
    do
      if opts[:config] do
        Cmake.Config.cmd(dirs, opts)
      end

      Cmake.Build.cmd(dirs, opts)
      Cmake.Install.cmd(dirs, opts)
    end
  end

  @doc """
  Invoke cmake command with `args`.
  """
  def cmake(build_dir, args, env) do
    build_path  = build_path(build_dir)

    opts = [
      cd: build_path,
      env: env,
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    # make build directory
    unless File.exists?(build_path), do: File.mkdir_p(build_path)

    if "--verbose" in args do
      IO.inspect([args: args, opts: opts])
    end

    {%IO.Stream{}, status} = System.cmd("cmake", args, opts)
    (status == 0)
  end

  @doc """
  Returns true if the build directory exists.
  """
  def build_dir_exists?(build_dir) do
    build_path(build_dir)
    |> File.exists?()
  end

  @doc """
  Remove cmake build directory. (interpret pseudo-path)
  """
  def remove_build(build_dir) do
    build_path = build_path(build_dir)
    File.rm_rf!(build_path)
  end

  @doc """

  """
  def remove_cache(build_dir) do
    build_path = build_path(build_dir)

    IO.puts("-- remove CMakeCache.txt")
    cache_path = Path.join(build_path, "CMakeCache.txt")
    File.rm(cache_path)
  end

  # interpret pseudo-path
  defp build_path(:local),  do: Mix.Project.build_path() |> Path.join(".cmake_build")
  defp build_path(:global), do: Path.absname(System.user_home) |> Path.join(".#{app_name()}")
  defp build_path(dir),     do: Path.expand(dir)

  @doc """
  Get application name.
  """
  def app_name(), do: Atom.to_string(Mix.Project.config[:app])

  @doc """
  Get build/source directory.
  """
  def get_dirs(dirs, config) do
    case dirs do
      [build, source] -> [build, source]
      [build]         -> [build, config[:source_dir]]
      []              -> [config[:build_dir], config[:source_dir]]
      _ -> exit("illegal arguments")
    end
  end

  @doc """
  Get :cmake configuration from Mix.exs.
  """
  def get_config() do
    Keyword.get(Mix.Project.config(), :cmake, [])
    # default setting if it has no configuration
    |> Keyword.put_new(:build_dir, :local)
    |> Keyword.put_new(:source_dir, File.cwd!)
    |> Keyword.put_new(:config_opts, [])
    |> Keyword.put_new(:build_opts, [])
  end

  @doc """
  Return a map of default environment variables.
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

  defp env(var, default), do: (System.get_env(var) || default)

  @doc """
  Add an environment variable for child process.
  """
  def add_env(env, _name, nil),                 do: env
  def add_env(env, name, true),                 do: Map.put(env, name, "true")
  def add_env(env, name, i) when is_integer(i), do: Map.put(env, name, Integer.to_string(i))
  def add_env(env, name, f) when is_float(f),   do: Map.put(env, name, Float.to_string(f))
  def add_env(env, name, a) when is_atom(a),    do: Map.put(env, name, Atom.to_string(a))
  def add_env(env, name, s),                    do: Map.put(env, name, s)

  @doc """
  parse command line arguments. (custom)
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
        do_parse(rest, config, store_opts(opts, option, value, config), args)
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

  defp store_opts(opts, option, value, config) do
    kind = Keyword.get(config, :switches) || Keyword.get(config, :strict)
      |> Keyword.get(option)
      |> List.wrap()

    cond do
      :keep in kind ->
        [{option, value}|opts]
      true ->
        [{option, value}|Keyword.delete(opts, option)]
    end
  end

  def next(argv, opts \\ [])
  def next(["++"|rest], _opts), do: {:second, rest}
  def next(["--"|rest], _opts), do: {:second, rest}
  defdelegate next(argv, opts), to: OptionParser
end
