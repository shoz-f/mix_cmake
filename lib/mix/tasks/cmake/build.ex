defmodule Mix.Tasks.Cmake.Build do
  use Mix.Task

  require Mix.Tasks.Cmake
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

  @switches [
    parallel: :integer,
    target:   :string,
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
        |> Cmake.conj_front(opts[:parallel], ["--parallel", "#{opts[:parallel]}"])
        |> Cmake.conj_front(opts[:target], ["--target", "#{opts[:target]}"])

      cmake_env = Cmake.default_env()
        |> Cmake.add_env("CMAKE_BUILD_PARALLEL_LEVEL", cmake_config[:build_parallel_level])

      Cmake.build(build_dir, cmake_args, cmake_env)
    end
  end
end
