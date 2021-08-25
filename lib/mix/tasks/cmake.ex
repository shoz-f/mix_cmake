defmodule Mix.Tasks.Cmake do
  alias Mix.Tasks.Cmake

  defmodule Init do
    use Mix.Task
    import Mix.Generator
    
    @moduledoc """
    """
    @shortdoc "Create CMakeLists.txt"
    
    def run(_argv) do
      assigns = [
        app_name: Cmake.app_name()
      ]
    
      create_file("CMakeLists.txt", cmakelists_template(assigns))
    end
    
    embed_template(:cmakelists, """
    #
    # Copyright 2020 The TensorFlow Authors. All Rights Reserved.
    #
    # Licensed under the Apache License, Version 2.0 (the "License");
    # you may not use this file except in compliance with the License.
    # You may obtain a copy of the License at
    #
    #      https://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
    
    cmake_minimum_required(VERSION 3.18)
    project(<%= @app_name %> CXX)
    
    
    # main
    add_executable(<%= @app_name %>
      src/<%= @app_name %>.cc
    )
    target_link_libraries(<%= @app_name %>
    )
    
    install(TARGETS <%= @app_name %>
      RUNTIME
      DESTINATION ${CMAKE_SOURCE_DIR}/priv
    )
    """)
  end

  defmodule Config do
    use Mix.Task

    @moduledoc """
    """
    @shortdoc "Generate build scripts create based on the CMakeLists.txt"
    
    def run(argv \\ []) do
      with\
        {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: [verbose: :boolean])
      do
        cmake_config = Cmake.get_config()

        [build_dir, source_dir] = case dirs do
          [build, source] -> [build, source]
          [build]         -> [build, cmake_config[:source_dir]]
          []              -> [cmake_config[:build_dir], cmake_config[:source_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()
          |> Cmake.add_env("CMAKE_GENERATOR", cmake_config[:generator])

        Cmake.config(build_dir, source_dir, cmake_args, cmake_env)
      end
    end
  end

  defmodule Build do
    use Mix.Task

    @moduledoc """
    """
    @shortdoc "Build the CMake application"
    
    def run(argv \\ []) do
      with\
        {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: [verbose: :boolean])
      do
        cmake_config = Cmake.get_config()

        [build_dir] = case dirs do
          [build] -> [build]
          []      -> [cmake_config[:build_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()
          |> Cmake.add_env("CMAKE_BUILD_PARALLEL_LEVEL", cmake_config[:build_parallel_level])

        Cmake.build(build_dir, cmake_args, cmake_env)
      end
    end
  end
  
  defmodule Install do
    use Mix.Task
    
    @moduledoc """
    """
    @shortdoc "Install the application to the project's priv"
    
    def run(argv \\ []) do
      with\
        {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: [verbose: :boolean])
      do
        cmake_config = Cmake.get_config()

        [build_dir] = case dirs do
          [build] -> [build]
          []      -> [cmake_config[:build_dir]]
          _ -> exit("illegal arguments")
        end

        cmake_env = Cmake.default_env()

        Cmake.install(build_dir, cmake_args, cmake_env)
      end
    end
  end
  
  defmodule All do
    use Mix.Task

    def run(_argv) do
      Config.run()
      Build.run()
      Install.run()
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

  def build(build_dir, args \\ [], env \\ %{}), do: cmake(build_path(build_dir), ["--build", "."] ++ args, env)

  def install(build_dir, args \\ [], env \\ %{}), do: cmake(build_path(build_dir), ["--install", "."] ++ args, env)

  defp cmake(build_path, args, env) do
    opts = [
      cd: build_path,
      env: env,
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

#    IO.inspect([args: args, opts: opts])

    {%IO.Stream{}, status} = System.cmd("cmake", args, opts)
    (status == 0)
  end

  def app_name() do
    Mix.Project.config[:app]
    |> Atom.to_string()
  end

  defp build_path(:local) do
    Mix.Project.build_path()
    |> Path.join("cmake")
  end

  defp build_path(:global) do
    app_name = app_name()

    System.user_home
    |> Path.absname()
    |> Path.join(".#{app_name}")
  end

  defp build_path(dir), do: Path.expand(dir)

  def get_config() do
    Keyword.get(Mix.Project.config(), :cmake, [])
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
      {:undefined, key, _value, _rest} ->
        {:undefined, key}
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
