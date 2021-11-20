# Mix Cmake

Mix Cmake is Elixir mix task to run Cmake build tool.

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
At the first, you need to prepare the "CMakeLists.txt" for your project.
Mix Cmake can generate boiler plate "CMakeLists.txt" if you want. It also make a snipet of cmake/0 - Cmake configuration.

```shell
$ cd <your project>
$ mix cmake.init
```

After that, you will invoke sub-command `config`, `build` and `install` in order or invoke all in one command.

```shell:sub command style
$ mix cmake.config
$ mix cmake.build
$ mix cmake.install
```

```shell:all in one style
$ mix cmake --config
```

Of course, `config` sub-command need to be run once. "mix cmake" with no options executes `build` and `install` only.

You can remove optupts of `build` to invoke sub-command `clean`.

```shell
$ mix cmake.clean
```

CAUTION: `clean`'s option `--all` means to remove whole BUILD working directory. You have to run `mix cmake.config` next time. 

## License
Npy is licensed under the Apache License Version 2.0.
