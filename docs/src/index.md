[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://eben60.github.io/ShareAdd.jl/) 
[![Build Status](https://github.com/Eben60/ShareAdd.jl/workflows/CI/badge.svg)](https://github.com/Eben60/ShareAdd.jl/actions?query=workflow%3ACI) 
[![Coverage](https://codecov.io/gh/Eben60/ShareAdd.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Eben60/ShareAdd.jl) 
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


# ShareAdd.jl

This Julia package helps to reduce clutter in your main shared environment (and thus avoid package incompatibility problems) by making it easy to use multiple shared or temporary environments. It exports two macros: [`@usingany`](@ref) and [`@usingtmp`](@ref), envisioned for two different workflows. The package also provides several [utility functions](@ref "Some other functions and usage cases") for managing shared environments.

## Glossary

*The definitions below deviate somewhat from the strict definitions of Environment, Project, and Package as given in the Julia docs, and refer to the most common and relevant cases.*

- __Project File__: The `Project.toml` file in environment's folder. Its `deps` section lists packages available in this env. May contain additional data like compatibility requirements. [🔗](https://docs.julialang.org/en/v1/manual/code-loading/#Project-environments) 
- __Manifest__: `TOML`-format file in environment's folder. It contains the actual state of the environment, including all indirect dependencies and their versions. Environment can contain multiple *Manifest* files for different Julia versions. [🔗](https://pkgdocs.julialang.org/v1/toml-files/#Manifest.toml) 
- __Environment__: Simply a folder containing a `Project.toml` and optionally a *Manifest* file. Projects or packages are also environments. All packages in the `Project.toml` of the active environment are available for import. [🔗](https://docs.julialang.org/en/v1/manual/code-loading/#Environments)
- __Shared Environment__: Any environment in the `path-to-Julia/.Julia/environments` folder. These environments can be addressed by prepending `@` to the env name, without typing it's whole path. Typically shared environments do not contain projects. [🔗](https://pkgdocs.julialang.org/v1/environments/#Shared-environments)
- __Main / Default Environment__: The subfolder in the environments folder, named according to the Julia minor version , e.g. for Julia v1.11 it's name will be `v1.11`. This is the default env upon start of Julia, except Julia was started with some specific project. Especially for novices it is common to work in the default environment and install all packages therein. This may result in compat conflicts. The motivation to create `ShareAdd` was to help avoiding this kind of situaltion.
- __`LOAD_PATH`__: An array of currently available environments. The default value is `["@", "@v#.#", "@stdlib"]`, where `"@"` refers to the current project, and `"@v#.#"` stands for the "main" env. Environments can be added both in the form of env folder paths, or, for shared envs, as the env name prepended by `@` - e.g. `["@", "@v#.#", "@stdlib", "@MyTools"]`. 
- __Stacked Environments__: A concept of using multiple environments at the same time, so that the packages from each environment are available. Realized by having multiple (shared) envs in the `LOAD_PATH`. This is the main mechanism behind `ShareAdd`. [🔗](https://docs.julialang.org/en/v1/manual/code-loading/#Environment-stacks).
- __Project__: A directory containing a `Project.toml` file as well as the source and other relevant files. Project is a subtype of environment.
- __Package__: Is a project adhering to a certain structure, which contains the source files and other resources, suitable for distribution. Packages can be loaded with `using` or `import`. [🔗](https://docs.julialang.org/en/v1/manual/code-loading/#Package-directories) 

## Installation and first steps

It is recommmended to install ShareAdd into your main (a.k.a. default) shared environment:

```
(Foo) pkg> activate # this is to switch to the default env
  Activating project at `~/.julia/environments/v1.11`

(@v1.11) pkg> add ShareAdd
``` 

After the installation, you could use the [`ShareAdd.info()`](@ref) function to check the state of your shared environment(s), and [`ShareAdd.tidyup()`](@ref) to move most of the packages from your main shared env into other shared environments. You may also want to add `using ShareAdd` directive to your `startup.jl` file. 

## `@usingany` macro

> **⚠️ Note for Julia v1.12 in VSCode**  
> `@usingany` may need to install new packages, with dialogs implemented via `REPL.TerminalMenus`, which appear to be broken with Julia **v1.12** in **VSCode**. See [below](@ref "Note for Julia v1.12 in VSCode") for more info and workarounds. Importing already installed packages by `@usingany` (the most common usage) works OK.

This macro makes package(s) available, if they are not already, and loads them with `using` keyword.

- If a package is available in an environment in `LOAD_PATH`, that's OK.
- If a package is available in a [shared environment](https://pkgdocs.julialang.org/v1/environments/#Shared-environments), this environment will be pushed into `LOAD_PATH`.
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

If your currently used Julia version supports [versioned manifests](https://pkgdocs.julialang.org/v1/toml-files/#Different-Manifests-for-Different-Julia-versions) (i.e. >= v1.10.8), then on any updates using `ShareAdd` package (see [`ShareAdd.update`](@ref)), a versioned manifest will be created in each updated env. The function [`ShareAdd.make_current_mnf`](@ref) can also be used to create a versioned manifest in a specified environment without updating it.

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

The macro [`@showenv`](@ref) (with or without arguments) will open an environment folder in your desktop GUI, saving you from a bit of hassle of getting to hidden folder.

The functions [`ShareAdd.info()`](@ref), [`ShareAdd.update()`](@ref), [`ShareAdd.delete()`](@ref) do what their names say.

The function [`ShareAdd.make_importable`](@ref) also does what it says. It is used internally by [`@usingany`](@ref), but it can also be used separately in special cases, e.g. if you need `using A as B` syntax, or want to import a package via `import` statement instead of `using`:

```
using ShareAdd: make_importable
make_importable("Foo")
import Foo
```

## Workflow for upgrading Julia or moving to a different computer.

### Upgrading Julia

Each Julia minor version has it's main shared environment in the correspondingly named folder, e.g. for Julia v1.11 the folder name is `v1.11`, for the next version it will be `v1.12`. All other shared environments are commonly used by all Julia versions. 

For an upgrade e.g. from Julia v1.11 to v1.12 you can proceed as following:

- Before the very first run of Julia v1.12, make a copy of `v1.11` folder, and name it `v1.12`. You can use [`@showenv`](@ref) macro without arguments to open the environments folder in your desktop GUI. 
  - Then, upon upgrade to Julia v1.12, update first the new main environment from the `Pkg` command line, 
  - then update all shared environments with the help of `ShareAdd`. `ShareAdd.update()` will create version-specific manifests, thus ensuring that you can use the same shared env with different versions of Julia without conflicts:

```
(SomeEnv) pkg> activate # calling activate without arguments will activate the main env
  Activating project at `~/.julia/environments/v1.12`

(@v1.12) pkg> update
# update info

julia> using ShareAdd

julia> ShareAdd.update()
# a lot of update infos
```

- Alternatively, if you have already run Julia v1.12 and thus the `v1.12` folder has already been created,
  - add `ShareAdd` to your main environment,
  - update all shared environments using `ShareAdd.update()`.

### Moving to a different computer

The procedure is in parts similar to described above for Julia upgrade.

- Open the environments folder e.g. by calling [`@showenv`](@ref).
- Copy all folders you want to transfer,
- and paste them into the environments folder on the new computer.
- If the main env folder (e.g. `v1.11`) was among the copied, `ShareAdd` is assumed to be installed, otherwise install it there.
- Update the main environment from the `Pkg` command line.
- Update all shared environments using `ShareAdd.update()`.  

## Note for Julia v1.12 in VSCode

Some of the `ShareAdd` functions may start user dialogs, which are implemented through [`REPL.TerminalMenus`](https://docs.julialang.org/en/v1/stdlib/REPL/#REPL.TerminalMenus), a part of the Julia's standard library package [`REPL`](https://docs.julialang.org/en/v1/stdlib/REPL/#REPL). Unfortunately `REPL.TerminalMenus` appear to be broken with Julia `v1.12` in VSCode, as of Julia `v1.12.0-beta4`. Actually it was not working perfectly in `VSCode` under previous versions of Julia too (s. [this issue](https://github.com/julia-vscode/julia-vscode/issues/2668) and links therein), but it is now [much worse](https://github.com/julia-vscode/julia-vscode/issues/3833) under `v1.12`. 

Whether the dialog will be started depends on specific circumstances, e.g. for `@usingany` it is if a package to be imported is already available in some shared env. Before starting such a dialog, if Julia ≥ v1.12 under VSCode environment is detected, a warning will be issued, giving the user the opportunity to press `Ctrl/C`. 

In such a case you may execute the ShareAdd macro/function from Terminal, or run your script from Terminal, or execute VSCode command "Julia: Run File in New Process" once. After the package or env installation/moving/deletion, you can return to the normal use of VSCode. Alternatively you can just perform the action using `Pkg` functions. 

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
Filter = t -> (Base.isexported(ShareAdd, nameof(t)) || Base.ispublic(ShareAdd, nameof(t)))
```
