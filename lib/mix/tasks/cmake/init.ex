defmodule Mix.Tasks.Cmake.Init do
  use Mix.Task
  import Mix.Generator
  
  alias Mix.Tasks.Cmake
  
  @shortdoc "Create CMakeLists.txt"
  @moduledoc """
  Create CMakeLists.txt
  
  $ mix cmake.init [source_dir]
  """

  def run(argv) do
    [source_dir] = case argv do
      [source] -> [source]
      []       -> [File.cwd!]
      _ -> exit("illegal arguments")
    end
    
    assigns = [
      app_name: Cmake.app_name()
    ]
    create_file(Path.join(source_dir, "CMakeLists.txt"), cmakelists_template(assigns))
    create_file(Path.join(source_dir, "cmake.cfg"), cmakecfg_template([]))
  end
  
  embed_template(:cmakelists, """
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
  
  embed_template(:cmakecfg, """
    # Cmake configuration.
    defp cmake do
      [
        # Specify cmake build directory or pseudo-location {:local, :global}.
        #   :local(default) - "./_build/.cmake_build"
        #   :global - "~/.\#{Cmake.app_name()}"
        #
        #build_dir: :local,
        
        # Specify cmake source directory.(default: File.cwd!)
        #
        #source_dir: File.cwd!,
        
        # Specify generator name.
        # "cmake --help" shows you build-in generators list.
        #
        #generator: "",
        
        # Specify jobs parallel level.
        #
        #build_parallel_level: 1
      ]
    end
  """)
end
