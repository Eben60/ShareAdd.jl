[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://eben60.github.io/ShareAdd.jl/) 
[![Build Status](https://github.com/Eben60/ShareAdd.jl/workflows/CI/badge.svg)](https://github.com/Eben60/ShareAdd.jl/actions?query=workflow%3ACI) 
[![Coverage](https://codecov.io/gh/Eben60/ShareAdd.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Eben60/ShareAdd.jl) 
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


# ShareAdd.jl

This Julia package is intended for interactive use, and it's aim is to help you in reducing clutter in your main shared environment, and thus avoid package incompatibility problems. It exports two macros: [`@usingany`](@ref) and [`@usingtmp`](@ref), envisioned for two different workflows. The package also provides several [utility functions](@ref "Some other functions and usage cases") for managing shared environments.

## `@usingany` macro

This macro makes package(s) available, if they are not already, and loads them with `using` keyword.

- If a package is available in an environment in LOAD_PATH, that's OK.
- If a package is available in a [shared environment](https://pkgdocs.julialang.org/v1/environments/#Shared-environments), this environment will be pushed into LOAD_PATH.
- Otherwise if it can be installed, you will be prompted to select an environment to install the package(s).
- If the package is not listed in any registry, an error will be thrown. 

```
# simplest usage case
@usingany SomePackage
```

For more usage options see [`@usingany` docs](@ref) .

### `@usingany` usage example

Let's assume, while working on your package `MyPackage`, we temporarily need packages `TOML`, `Plots`, and `Chairmarks`. However, they shouldn't be added permanently to your package dependencies. Furthermore, from the package `BenchmarkTools` we need only the macro `@btime` and the function `save`. We also need `Unitful`, which is already an installed dependence of `MyPackage`.

`TOML` is available in the `stdlib`, `Plots` and `BenchmarkTools` you already put into a shared environment `@utilities`, and `Chairmarks` is not on your computer yet. 

Now, first, you add ShareAdd to your "main" (standard) enviroment, making it available at all times:

```
]
(YourEnv) pkg> activate 
  Activating project at `~/.julia/environments/v1.11`

(@v1.11) pkg> add ShareAdd
(...)
(@v1.11 pkg> activate . # back to your environment
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

Afterwards `@utilities` (and `@Chairmarks`, if created) will be added to `LOAD_PATH`, making their packages available.

Finally, the macros will execute `using Unitful, TOML, Plots, Chairmarks` resp. `using BenchmarkTools: @btime, save` - and that's it. Enjoy!

### `@usingany` with updates

By setting the corresponding kwarg, it is possible to first update the packages and/or environments prior to execution of import. E.g. the following command would update the packages `Pkg1`, `Pkg2` in their shared environments:

```
using ShareAdd
@usingany update_pkg = true Pkg1, Pkg2
```

### `@usingany` without explicitly calling `@usingany`

`ShareAdd.jl` can be combined nicely with [`BasicAutoloads.jl`](https://juliahub.com/ui/Packages/General/BasicAutoloads). See this [Discourse post](https://discourse.julialang.org/t/ann-shareadd-jl-making-easy-to-import-packages-from-multiple-environments/121261/3?u=eben60) to learn how get packages silently loaded if you call their functions in the REPL - e.g. if you type `mean([1,2,3])` or `1.55u"V"`. 

## Versioned manifests

If currently used Julia version supports [versioned manifests](https://pkgdocs.julialang.org/v1/toml-files/#Different-Manifests-for-Different-Julia-versions) (i.e. >= v1.11), then on any updates using `ShareAdd` package (see [`ShareAdd.update`](@ref)), a versioned manifest will be created in each updated env. The function [`ShareAdd.make_current_mnf`](@ref) can also be used to create a versioned manifest in a specified environment without updating it.

## `@usingtmp` macro

This macro activates a temporary environment, optionally installs packages into it, and loads them with `using` keyword. 

- If current environment is already a temporary one, environment is not changed.
- If current env was a project (not package!), a temporary env will be activated.
- If current env was a package (under development), e.g. `MyPkg`, a temporary env will be activated, AND `MyPkg` will be [dev](https://pkgdocs.julialang.org/v1/api/#Pkg.develop)-ed in that temporary env. 

Thу last one is actually the interesting case, as you can continue to work on `MyPkg`, while temporarily having additional packages available.

If `@usingtmp` was called with arguments, the corresponding packages will be installed into that temporary env, 
and imported with `using` keyword.

```
using ShareAdd
@usingtmp Foo, Bar
@usingtmp Baz: quux
```

## Some other functions and usage cases

The functions [`ShareAdd.info()`](@ref), [`ShareAdd.update()`](@ref), [`ShareAdd.delete()`](@ref) do what their names say.

__TODO__ [`@showenv`](@ref)

The function [`ShareAdd.make_importable`](@ref) also does what it says. It is used internally by [`@usingany`](@ref), but it can also be used separately in special cases, e.g. if you need `using A as B` syntax, or want to import a package via `import` statement instead of `using`:

```
using ShareAdd: make_importable
make_importable("Foo")
import Foo
```

## Reference

### Exported macros

```@autodocs
Modules = [ShareAdd]
Order   = [:macro, ]
```

### Public functions

```@autodocs
Modules = [ShareAdd]
Order   = [:function]
Filter = t -> (! Base.isexported(ShareAdd, nameof(t)) && Base.ispublic(ShareAdd, nameof(t)))
```

### Public types

```@autodocs
Modules = [ShareAdd]
Order   = [:type, ]
Filter = t -> (! Base.isexported(ShareAdd, nameof(t)) && Base.ispublic(ShareAdd, nameof(t)))
```
