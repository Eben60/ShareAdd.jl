"""
    delete(nms::Union{String, Vector{String}}; inall=false)

Deletes shared envs, or packages therein.

If the provided argument is name(s) of shared environment(s), as specified by leading "@" in the names(s): then 
deletes the shared environment(s) by erasing their directory.

Otherwise, the provided name(s) are package names: then for each package `pkg` deletes it from it's shared environment. 
Deletes this environment if it was the only package there. If the package may be present in multiple environments, 
and you want to delete it from all of them, set `inall=true`.

# Keyword argument

- `inall=false`: If set to `true`, would delete package from multiple environments. Has no effect, if provided `nms` is/are env name(s).

Returns `nothing`.

This function is public, not exported.
"""
function delete(nms::AbstractVector{<:AbstractString}; inall=false)
    all_same_art(nms) || error("List of names must be either all environments or all packages")
    delete.(nms; inall)
    return nothing
end

function delete(nm::AbstractString; inall=false)
    if startswith(nm, "@")
        delete_shared_env(nm)
    else
        delete_shared_pkg(nm; inall)
    end
    return nothing
end

"""
    delete_shared_env(env::Union{AbstractString, EnvInfo})

Deletes the shared environment `env` by erasing it's directory.

Returns `nothing`.
"""
delete_shared_env(e::EnvInfo) = (rm(e.path; recursive=true); return nothing)

function delete_shared_env(s::AbstractString) # TODO check if in load path
    startswith(s, "@") || error("Name of shared environment must start with @")
    s = s[2:end]

    env = shared_environments_envinfos().shared_envs[s]
    return delete_shared_env(env)
end

"""
    delete_shared_pkg(pkg::AbstractString; inall=false)

Deletes the package `pkg` from it's shared environment. Deletes this environment if it was the only package there.
If the package may be present in multiple environments, and you want to delete it from all of them, set `inall=true`.

Returns `nothing`.
"""
function delete_shared_pkg(pkname::AbstractString; inall=false)
    curr_env = current_env()
    pkinfos = list_shared_packages(; std_lib = false) # packages in stdlib are not deleteable
    haskey(pkinfos, pkname) || error("Package $(pkname) not found in any shared environment")

    p = pkinfos[pkname]
    
    length(p.envs) > 1 && !inall && 
        error("Package $pkname is present in multiple environments $([env.name for env in p.envs]). Remove it manually, or set `inall=true`.")
 
    emptyenvs = EnvInfo[]
    for e in p.envs
        if e.in_path && pkg_isloaded(pkname)
            @warn """The env "$(e.name)" is in path, and package "$(pkname)" is loaded. It will not be removed from "$(e.name)"."""
        else
            (length(e.pkgs) == 1) && !e.standard_env && push!(emptyenvs, e)
            Pkg.activate(e.path)
            Pkg.rm(pkname)
        end
    end

    Pkg.activate(curr_env.path)
    for e in emptyenvs
        delete_shared_env(e)
    end

    return nothing
end

pkg_isloaded(pkg) = String(pkg) in [k.name for k in keys(Main.Base.loaded_modules)]

"""
    reset()

Resets the `LOAD_PATH` to it's default value of `["@", "@v#.#", "@stdlib"]`, thus removing any manually added paths. 

This function is public, not exported.
"""
function reset()
# function reset_loadpath!()
    default_paths = ["@", "@v#.#", "@stdlib"]
    empty!(LOAD_PATH)
    append!(LOAD_PATH, default_paths)
    return nothing  
end