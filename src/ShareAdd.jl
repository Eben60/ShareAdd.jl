"""
This Julia package exports macro `@usingany`. This macro makes package(s) available, if they are not already, and loads them with `using` keyword.

- If a package is available in an environment in LOAD_PATH, that's OK.
- If a package is available in a shared environment, this environment will be pushed into LOAD_PATH.
- Otherwise if it can be installed, you will be prompted to select an environment to install the package(s).
- If the package is not listed in any registry, an error will be thrown. 
"""
module ShareAdd
using TOML, Pkg
using REPL.TerminalMenus

include("types.jl")
include("optimset.jl")
include("environments.jl")

export @usingany
export sh_add, reset_loadpath!, delete_shared_env, delete_shared_pkg

if VERSION >= v"1.11.0-DEV.469"
    include("public.julia")
end

using PrecompileTools: @compile_workload
include("precompile.jl")

end # module ShAdd
