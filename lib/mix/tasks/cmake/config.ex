defmodule  Mix.Tasks.Cmake.Config do
  use Mix.Task

  alias Mix.Tasks.Cmake

  @shortdoc "Generate build scripts based on the CMakeLists.txt"
  @moduledoc """
  Generate build scripts based on the 'CMakeLists.txt'.
  
    mix cmake.config [build_dir] [source_dir] [++ CMake options]
  
  ## Command line options
  
  ## Configuration

  * `:build_dir` - 
  * `:source_dir` -
  * `:generator` -
  """
  
  def run(argv) do
    with\
      {:ok, _opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: [verbose: :boolean])
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
