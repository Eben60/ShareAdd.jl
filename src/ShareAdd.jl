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

end # module ShAdd
