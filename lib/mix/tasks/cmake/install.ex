defmodule Mix.Tasks.Cmake.Install do
  use Mix.Task
  
  alias Mix.Tasks.Cmake
  require Cmake

  @shortdoc "Install the application to the project's priv"
  @moduledoc """
  Install the application to the project's priv.
  
    mix cmake.install [opt] [build_dir]
  
  ## Command line options

  * `--strip`    -
  * `--verbose`  -
  
  ## Configuration

  * `:build_dir` - 
  """
  
  @switches [
    strip:   :boolean,
    verbose: :boolean,
  ]

  def run(argv) do
    with\
      {:ok, opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: @switches)
    do
      cmake_config = Cmake.get_config()

      [build_dir] = case dirs do
        [build] -> [build]
        []      -> [cmake_config[:build_dir]]
        _ -> exit("illegal arguments")
      end

      cmake_args = cmake_args
        |> Cmake.conj_front(opts[:verbose],  ["--verbose"])
        |> Cmake.conj_front(opts[:strip],    ["--strip"])

      cmake_env = Cmake.default_env()

      Cmake.install(build_dir, cmake_args, cmake_env)
    end
  end
end
