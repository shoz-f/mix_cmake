defmodule Mix.Tasks.Cmake.Install do
  use Mix.Task
  
  alias Mix.Tasks.Cmake

  @shortdoc "Install the application to the project's priv"
  @moduledoc """
  Install the application to the project's priv.
  
    mix cmake.install [build_dir]
  
  ## Command line options
  
  ## Configuration

  * `:build_dir` - 
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

      Cmake.install(build_dir, cmake_args, cmake_env)
    end
  end
end
