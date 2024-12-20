"""
    Package ShareAdd v$(pkgversion(ShareAdd))

This Julia package exports macro `@usingany`. This macro makes package(s) available, if they are not already, and loads 
them with `using` keyword. 

- If a package is available in an environment in `LOAD_PATH`, that's OK.
- If a package is available in a shared environment, this environment will be pushed into `LOAD_PATH`.
- Otherwise if package(s) can be installed, you will be prompted to select an environment to install each package.
- If the package is not listed in any registry, an error will be thrown.

Documentation under https://eben60.github.io/ShareAdd.jl/
$(isnothing(get(ENV, "CI", nothing)) ? ("\n" * "Package local path: " * pathof(ShareAdd)) : "")
"""
module ShareAdd
using TOML, Pkg
using REPL.TerminalMenus

include("types.jl")
include("optimset.jl")
include("environments.jl")
include("update_packages.jl")
include("temporary_envs.jl")
include("macros.jl")

export @usingany, @usingtmp
export delete_shared_env, delete_shared_pkg, list_shared_envs, list_shared_pkgs, 
    make_current_mnf, make_importable, reset_loadpath!, sh_add, update_shared

if VERSION >= v"1.11.0-DEV.469"
    include("public.julia")
end

using PrecompileTools: @compile_workload
include("precompile.jl")

end # module ShAdd
