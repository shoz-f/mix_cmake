defmodule Mix.Tasks.Cmake.Build do
  use Mix.Task

  alias Mix.Tasks.Cmake

  @shortdoc "Build the CMake application"
  @moduledoc """
  Build the CMake application.
  
    mix cmake.build [build_dir] [++ CMake options]
  
  ## Command line options
  
  ## Configuration

  * `:build_dir` - 
  * `:build_parallel_level` -
  """
  
  def run(argv \\ []) do
    with\
      {:ok, _opts, dirs, cmake_args} <- Cmake.parse_argv(argv, strict: [verbose: :boolean])
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
