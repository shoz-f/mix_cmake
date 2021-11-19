# Mix.Tasks.Cmake

Mix.Tasks.Cmake is Elixir mix task to run Cmake build tool.

## Installation
Add following dependency to your `mix.exs`.

```elixir
def deps do
  [
    {:mix_cmake, git: "https://github.com/shoz-f/mix_cmake.git"}
  ]
end
```

Optionaly you can include any Cmake configuration as `cmake:` attribute in project/0 list.

```elixir:mix.exs
...
  def project do
    [
      ...
      cmake: cmake()
    ]
  end
  
  def cmake() do
    [
      # Specify cmake build directory or pseudo-path {:local, :global}.
      #   :local(default) - "./_build/.cmake_build"
      #   :global - "~/.\#{Cmake.app_name()}"
      #
      build_dir: :local,
      
      # Specify cmake source directory.(default: File.cwd!)
      #
      source_dir: File.cwd!,
      
      # Specify generator name.
      # "cmake --help" shows you build-in generators list.
      #
      generator: "MSYS Makefiles",
      
      # Specify jobs parallel level.
      #
      build_parallel_level: 4
    ]
  end
```

## Basic Usage

## License
Npy is licensed under the Apache License Version 2.0.
