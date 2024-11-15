[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://eben60.github.io/ShareAdd.jl/) 
[![Build Status](https://github.com/Eben60/ShareAdd.jl/workflows/CI/badge.svg)](https://github.com/Eben60/ShareAdd.jl/actions?query=workflow%3ACI) 
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


# ShareAdd.jl

This Julia package is intended for interactive use. It exports the macro `@usingany`: This macro makes package(s) available, if they are not already, and loads them with `using` keyword.

- If a package is available in an environment in LOAD_PATH, that's OK.
- If a package is available in a [shared environment](https://pkgdocs.julialang.org/v1/environments/#Shared-environments), this environment will be pushed into LOAD_PATH.
- Otherwise if it can be installed, you will be prompted to select an environment to install the package(s).
- If the package is not listed in any registry, an error will be thrown. 

```
# simplest usage case
@usingany SomePackage
```

The package also exports several utility functions - see the [Exported functions](@ref) section.

## Usage example

Let's assume, while working on your package `MyPackage`, we temporarily need packages `TOML`, `Plots`, and `Chairmarks`. However, they shouldn't be added permanently to your package dependencies. Furthermore, from the package `BenchmarkTools` we need only the macro `@btime` and the function `save`. We also need `Unitful`, which is already an installed dependence of `MyPackage`.

`TOML` is available in the `stdlib`, `Plots` and `BenchmarkTools` you already put into a shared environment `@utilities`, and `Chairmarks` is not on your computer yet. 

Now, first, you add ShareAdd to your "main" (standard) enviroment, making it available at all times:

```
]
(YourEnv) pkg> activate 
  Activating project at `~/.julia/environments/v1.10`

(@v1.10) pkg> add ShareAdd
(...)
(@v1.10) pkg> activate . # back to your environment
(YourEnv) pkg> 
```

By that occasion you may also want to clean your standard environment: It is generally not recommended having a lot of packages there.

Now, the only thing you need is to type into REPL (or adding to your script) the following lines:

```
using ShareAdd
@usingany Unitful, TOML, Plots, Chairmarks
@usingany BenchmarkTools: @btime, save
```

As `Chairmarks` was not installed yet, you will be asked as to where to install it. You may e.g. add it to your existing `@utilities` shared environment, or let create a new environment `@Chairmarks` and put it there. 

Afrerwards `@utilities` (and `@Chairmarks`, if created) will be added to `LOAD_PATH`, making their packages available.

Finally, the macros will execute `using Unitful, TOML, Plots, Chairmarks` resp. `using BenchmarkTools: @btime, save` - and that's it. Enjoy!

## Other functions and usage cases

The function [`make_importable`](@ref) does what it's name says. It is used internally by [`@usingany`](@ref), but can be used separately e.g. 
if you e.g. want to import a package via `import` statement instead of `using`:

```
using ShareAdd
make_importable("Foo")
import Foo
```

It is possible to first update the packages and/or environments by setting the corresponding kwarg. E.g. the following would update the 
packages `Pkg1`, `Pkg2` in their shared environments:

```
using ShareAdd
@usingany update_pkg = true Pkg1, Pkg2
```

For usage options see [`@usingany` docs](@ref) .

## Likes & dislikes?

Star on GitHub, open an issue, contact me on Julia Discourse.

## Credits

Some code and inspiration from [EnvironmentMigrators.jl](https://github.com/mkitti/EnvironmentMigrators.jl) by Mark Kittisopikul. 

The AI from [Codeium](https://codeium.com/) helped me and bugged me (pun intended).

## Copyright and License

© 2024 Eben60

MIT License (see separate file `LICENSE`)

