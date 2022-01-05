# Mix Cmake

Mix Cmake is Elixir mix task to run Cmake build tool.

## Installation
Add following dependency to your `mix.exs`,

```elixir
def deps do
  [
    {:mix_cmake, "~> 0.1.0"}
  ]
end
```

and compile `mix_cmake`.

```shell
$ mix deps.get
$ mix deps.compile
==> mix_cmake
```

Optionaly you can include some Cmake configuration as `cmake:` attribute in project/0 list.

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
Mix Cmake can generate boiler plate "CMakeLists.txt" if you want. It also make a snipet of cmake/0 - Cmake configuration - including to `mix.exs`.

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

You can remove optupts built by Cmake to invoke sub-command `clean`.

```shell
$ mix cmake.clean
```

CAUTION: `clean`'s option `--all` means to remove WHOLE BUILD working directory. You will have to run `mix cmake.config` next time. 

## Compiler Task
There is also a compiler task - Mix.Tasks.Compile.Cmake. You can execute cmake by invoking `mix compile`.
In this case, you need to add the following settings to `mix.exs`.

```elixir
def project() do
[
  app: :myapp,
  deps: deps(),
  compilers: [:cmake] ++ Mix.compilers,
  
  cmake: [
    build_dir: :local,
    build_parallel_level: 4,
    ...
  ]
]
end
```

## License
Mix Cmake is licensed under the Apache License Version 2.0.
