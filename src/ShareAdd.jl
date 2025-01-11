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

These are all public, but not exported to avoid name conflicts.

# Examples
```julia-repl
julia> ShareAdd.update("Plots")
  Activating project at `~/.julia/environments/Plotting`
# ... a screenful of update information
julia> @usingany Plots
julia> plot(xs, ys)
```

Reference: see docstrings.

Documentation: https://eben60.github.io/ShareAdd.jl/
$(isnothing(get(ENV, "CI", nothing)) ? ("\n" * "Package local path: " * pathof(ShareAdd)) : "")
"""
module ShareAdd
using TOML, Pkg
using REPL.TerminalMenus
# using OrderedCollections

include("types.jl")
include("optimset.jl")
include("environments.jl")
include("info.jl")
include("utils_env.jl")
include("update_packages.jl")
include("temporary_envs.jl")
include("macros.jl")

export @usingany, @usingtmp

if VERSION >= v"1.11.0-DEV.469"
    include("public.julia")
end

using PrecompileTools: @compile_workload
include("precompile.jl")

# """
#     publicity(md, ent, grade::Integer)

# - `md`: Module
# - `ent`: Entity (a function, type, etc.)
# - `grade`: 0 - the entity is private, 1 - public, 2 - exported
# """
# function publicity(md, ent, grade::Integer)
#     nms = names(md; all=true)

#     if grade == 0
#         f = filter(x -> !Base.ispublic(md, x))
#     elseif grade == 1
#         f = filter(x -> Base.ispublic(md, x) && !Base.isexported(md, x) )
#     else
#         f = filter(x -> Base.isexported(md, x) )
#     end

#     names_subset = f(nms)
#     return ent in getproperty.(Ref(md), names_subset)
# end
# export publicity



end # module ShAdd
