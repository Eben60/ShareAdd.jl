"""
    Package ShareAdd v$(pkgversion(ShareAdd))

This Julia package exports macro `@usingany`. This macro makes package(s) available, if they are not already, and loads 
them with `using` keyword. 

- If a package is available in an environment in `LOAD_PATH`, that's OK.
- If a package is available in a shared environment, this environment will be pushed into `LOAD_PATH`.
- Otherwise if package(s) can be installed, you will be prompted to select an environment to install each package.
- If the package is not listed in any registry, an error will be thrown.

There are also utility functions in ShareAdd that may help you manage shared environments, i.a.:

- [`ShareAdd.info`](@ref): lists information about shared envs and/or packages. 
- [`ShareAdd.update`](@ref): updates packages or environments
- [`ShareAdd.delete`](@ref): deletes packages or environments
- [`@showenv`](@ref): opens environment folders in your desktop GUI.

The functions are public, but not exported to avoid possible name conflicts. The `@showenv` macro is exported.

# Examples
```julia-repl
julia> ShareAdd.update("Plots")
  Activating project at `~/.julia/environments/Plotting`
# ... a screenful of update information
julia> @usingany Plots
julia> plot(xs, ys)
```

Reference: see docstrings.

The package name can be pronounced like "shair-ed".

Documentation: https://eben60.github.io/ShareAdd.jl/
$(isnothing(get(ENV, "CI", nothing)) ? ("\n" * "Package local path: " * pathof(ShareAdd)) : "")
"""
module ShareAdd
using TOML, Pkg
using REPL.TerminalMenus: RadioMenu

include("AbortableTerminalMenu/AbortableTerminalMenu.jl")
using .AbortableTerminalMenu: AbortableMultiSelectMenu, request

const testfolder_prefix = "z2del-0nzj"

include("types.jl")
include("optimset.jl")
include("env_infos.jl")
include("envs_interactive.jl")
include("info.jl")
include("utils_env.jl")
include("update_packages.jl")
include("temporary_envs.jl")
include("macros.jl")
include("showenv.jl")

export @usingany, @usingtmp
export @showenv
export SKIPPING, ASKING, FORCING

if VERSION >= v"1.11.0-DEV.469"
    include("public.julia")
end

@assert env_folders(; create=true).envs_exist

using PrecompileTools: @compile_workload
include("precompile.jl")

__init__() = cleanup_testenvs()


end # module ShAdd
