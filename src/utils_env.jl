"""
    delete(nms::Union{String, Vector{String}}; inall=false, force = false) -> nothing

Deletes shared envs, or packages therein.

If the provided argument is name(s) of shared environment(s), as specified by leading "@" in the names(s): then 
deletes the shared environment(s) by erasing their directory.

Otherwise, the provided name(s) are package names: then for each package `pkg` deletes it from it's shared environment. 
Deletes this environment if it was the only package there.

# Keyword arguments

- `inall=false`: If set to `true`, would delete package from multiple environments. Has no effect, if provided `nms` is/are env name(s).
- `force=false`: If set to `true`, would delete the package from a shared env even if the env is in path, and package is currently loaded.

# Examples
```julia-repl
julia> ShareAdd.delete("@TrialPackages")
julia> ShareAdd.delete("UnusedPkg"; inall=true)
julia> ShareAdd.delete("@Foo" => "bar")
```

This function is public, not exported.
"""
function delete(nms::AbstractVector{<:AbstractString}; inall=false, force = false)
    all_same_art(nms) || error("List of names must be either all environments or all packages")
    delete.(nms; inall, force)
    return nothing
end

function delete(nm::AbstractString; inall=false, force = false)
    if startswith(nm, "@")
        delete_shared_env(nm; force)
    else
        delete_shared_pkg(nm; inall, force)
    end
    return nothing
end

function delete(p::Pair{<:AbstractString, <:AbstractString}; force = false)
    curr_env = current_env()
    e = EnvInfo(p.first)
    delete_shared_pkg(p; force).nowempty && _delete_empty_envs([e], curr_env; force)
    return nothing
end

"""
    delete_shared_env(env::Union{AbstractString, EnvInfo}; force = false)

Deletes the shared environment `env` by erasing it's directory. Set `force=true` if you want to delete the environment even if it is currently in `LOAD_PATH`.

Returns `nothing`.
"""
function delete_shared_env(e::EnvInfo; force = false)
    if e.in_path && !force
        @warn """The env "$(e.name)" is in Path. It will not be removed from "$(e.name)"."""
    else
        rm(e.path; recursive=true);
    end
    return nothing
end

function delete_shared_env(s::AbstractString; force = false)
    startswith(s, "@") || error("Name of shared environment must start with @")
    s = s[2:end]

    env = shared_environments_envinfos().shared_envs[s]
    return delete_shared_env(env; force)
end

"""
    delete_shared_pkg(pkg::AbstractString; inall=false)

Deletes the package `pkg` from it's shared environment. Deletes this environment if it was the only package there.
If the package may be present in multiple environments, and you want to delete it from all of them, set `inall=true`.
Set `force=true` if you want to delete the package even if it is currently loaded.

Returns `nothing`.
"""
function delete_shared_pkg(pkname::AbstractString; inall=false, force = false)
    curr_env = current_env()
    pkinfos = list_shared_packages(; std_lib = false) # packages in stdlib are not deleteable
    haskey(pkinfos, pkname) || error("Package $(pkname) not found in any shared environment")

    p = pkinfos[pkname]
    
    length(p.envs) > 1 && !inall && 
        error("Package $pkname is present in multiple environments $([env.name for env in p.envs]). Remove it manually, or set `inall=true`.")
 
    emptyenvs = EnvInfo[]
    for e in p.envs
        (; nowempty) = delete_shared_pkg(e => pkname; force)
        nowempty && push!(emptyenvs, e)
    end

    _delete_empty_envs(emptyenvs, curr_env; force)

    return nothing
end

function _delete_empty_envs(emptyenvs::AbstractVector{EnvInfo}, curr_env; force = false)
    Pkg.activate(curr_env.path)
    for e in emptyenvs
        delete_shared_env(e)
        @info "Deleted empty shared env $(e.name)"
    end
    return nothing
end

function delete_shared_pkg(p::Pair{EnvInfo, <:AbstractString}; force = false)
    e, pkname = p
    nowempty = false
    
    if e.in_path && pkg_isloaded(pkname) && !force
        @warn """The env "$(e.name)" is in path, and package "$(pkname)" is loaded. It will not be removed from "$(e.name)"."""
    else
        (length(e.pkgs) == 1) && !e.standard_env && (nowempty = true)
        Pkg.activate(e.path)
        Pkg.rm(pkname)
    end
    return (; nowempty)
end

delete_shared_pkg(p::Pair{<:AbstractString, <:AbstractString}; force = false) = delete_shared_pkg(EnvInfo(p.first) => p.second; force)

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