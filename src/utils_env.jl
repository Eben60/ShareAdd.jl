"""
    SkipAskForceEnum

Options for deletion of environments and packages.

- `SKIPPING = -1`
- `ASKING = 0`
- `FORCING = 1`

This enum as well as it's values are exported. As `ShareAdd` is intended for interactive usage, and therefore the exported bindings are available in the `Main` module,
we use the "-ing" form to reduce the probability of name collisions.
"""
@enum SkipAskForceEnum begin
    SKIPPING = -1
    ASKING = 0
    FORCING = 1
end

"""
    delete(nms::Union{String, Vector{String}}; inall=ASKING, force = ASKING) -> nothing
    delete(nm::AbstractString; inall=ASKING, force = ASKING) -> nothing
    delete(p::Pair{<:AbstractString, <:AbstractString}; force = ASKING) -> nothing

Deletes shared envs, or packages therein.

If the provided argument is name(s) of shared environment(s), as specified by leading "@" in the names(s): then 
deletes the shared environment(s) by erasing their directories.

Otherwise, the provided name(s) are considered package names: then for each package `pkg` deletes it from it's shared environment(s). 
Afterwards deletes the environment if it left empty after package deletion.

You can also specify both the env and the package in the form  `"@Foo" => "bar"`

# Keyword arguments

Both kwargs accept any integer types, including Bool, as well as enum [`SkipAskForceEnum`](@ref) with integer values [-1=>SKIPPING, 0=>ASKING, 1=>FORCING]. If Bool is used, 
`false` is equivalent to `ASKING`, and `true` to `FORCING`

- `inall=ASKING`: If set to `FORCING`, would delete package from multiple environments, and with `SKIPPING` will skip without askung. Has no effect, if provided `nms` is/are env name(s).
- `force=ASKING`: If set to `FORCING`, would delete the env even if the env is currently in `LOAD_PATH`.

# Examples
```julia-repl
julia> ShareAdd.delete("@TrialPackages")
julia> ShareAdd.delete(["UnusedPkg", "UselessPkg"]; inall=true)
julia> ShareAdd.delete("@Foo" => "bar")
```

This function is public, not exported.
"""
function delete(nms::AbstractVector{<:AbstractString}; inall=ASKING, force = ASKING)
    force = SkipAskForceEnum(force |> Int)
    inall = SkipAskForceEnum(inall |> Int)
    all_same_art(nms) || error("List of names must be either all environments or all packages")
    delete.(nms; inall, force)
    return nothing
end

function delete(nm::AbstractString; inall=ASKING, force = ASKING)
    force = SkipAskForceEnum(force |> Int)
    inall = SkipAskForceEnum(inall |> Int)
    if startswith(nm, "@")
        delete_shared_env(nm; force)
    else
        delete_shared_pkg(nm; inall, force)
    end
    return nothing
end

function delete(p::Pair{<:AbstractString, <:AbstractString}; force = ASKING)
    curr_env = current_env()
    e = EnvInfo(p.first)
    delete_shared_pkg(p; force).now_empty && _delete_empty_envs([e], curr_env)
    return nothing
end

"""
    delete_shared_env(env::Union{AbstractString, EnvInfo}; force = SKIPPING)

Deletes the shared environment `env` by erasing it's directory. Set `force=FORCING` if you want to delete the environment even if it is currently in `LOAD_PATH`.

Returns `true`, if the environment has been deleted, and `false` otherwise.
"""
function delete_shared_env(e::EnvInfo; force::SkipAskForceEnum)
    if (force != FORCING) && e.in_path 
        if force == SKIPPING
            @warn """The env "$(e.name)" is in Path. It will not be removed."."""
            return false
        elseif force == ASKING
            askifdelete(e) || return false
        end
    end
    delete_from_loadpath("@$(e.name)")
    rm(e.path; recursive=true);
    return true
end

function delete_shared_env(s::AbstractString; force::SkipAskForceEnum)
    startswith(s, "@") || error("Name of shared environment must start with @")
    s = s[2:end]

    env = shared_environments_envinfos().shared_envs[s]
    return delete_shared_env(env; force)
end

function delete_from_loadpath(e)
    i = findfirst(isequal(e), LOAD_PATH)
    if i !== nothing
        deleteat!(LOAD_PATH, i)
    end
    return nothing
end

"""
    delete_shared_pkg(pkg::AbstractString; inall, force)
    delete_shared_pkg(p::Pair{EnvInfo, <:AbstractString}; force)
    delete_shared_pkg(p::Pair{<:AbstractString, <:AbstractString}; force)

Deletes the package `pkg` from it's shared environment. Deletes this environment if it was the only package there.
If the package may be present in multiple environments, and you want to delete it from all of them, set `inall=true`.
Set `force=true` if you want to delete the package even if it is currently loaded, and it's env, 
in case it is empty then, even if it is in `LOAD_PATH`.

Returns NamedTuple (; success, now_empty), where `now_empty` is a flag for the containing environment being now empty.
"""
function delete_shared_pkg(pkname::AbstractString; inall::SkipAskForceEnum, force::SkipAskForceEnum)
    curr_env = current_env()
    pkinfos = list_shared_packages(; std_lib = false) # packages in stdlib are not deleteable
    haskey(pkinfos, pkname) || error("Package $(pkname) not found in any shared environment")

    p = pkinfos[pkname]

    suggestion_loaded = "You may want to restart Julia, or you risk and call `delete` with kwarg `force=FORCING`."
    if (force != FORCING) && module_isloaded(p)
        if force == SKIPPING
            @warn "Package $pkname is currently loaded - aborting deletion. " *
                suggestion_loaded
            return (; success=false, now_empty=false)
        elseif force == ASKING
            if !askifdelete(p, loaded=true)
                @info "Package $pkname was not deleted."
                return (; success=false, now_empty=false)
            end
        end
    end

    suggestion_envs = """Remove it manually, or specify the env in the call e.g. `ShareAdd.delete("@$(p.envs[1].name)"=>"$(p.name)")`, or set `inall=true`."""
    if (inall != FORCING) && length(p.envs) > 1 
        if inall == SKIPPING
            @warn "Package $pkname is present in multiple environments $([env.name for env in p.envs]) - aborting deletion. " *
                suggestion_envs
            return (; success=false, now_empty=false)
        elseif inall == ASKING
            if !askifdelete(p, loaded=false)
                @info "Package $pkname was not deleted. $suggestion_envs"
                return (; success=false, now_empty=false)
            end
        end
    end
 
    emptyenvs = EnvInfo[]
    for e in p.envs
        (; now_empty) = delete_shared_pkg(e => pkname; force)
        now_empty && push!(emptyenvs, e)
    end

    _delete_empty_envs(emptyenvs, curr_env)

    return (; success=false, now_empty=missing)
end

function delete_shared_pkg(p::Pair{EnvInfo, <:AbstractString}; force #= kwarg ignored =#)
    e, pkname = p
    now_empty = false
    
    (length(e.pkgs) == 1) && !e.standard_env && (now_empty = true)
    Pkg.activate(e.path)
    Pkg.rm(pkname)

    return (; success=true, now_empty)
end

delete_shared_pkg(p::Pair{<:AbstractString, <:AbstractString}; force) = delete_shared_pkg(EnvInfo(p.first) => p.second; force)

function _delete_empty_envs(emptyenvs::AbstractVector{EnvInfo}, curr_env)
    Pkg.activate(curr_env.path)
    for e in emptyenvs
        delete_shared_env(e; force=FORCING)
        @info "Deleted empty shared env $(e.name)"
    end
    return nothing
end

module_isloaded(m) = string(m) in values(Base.loaded_modules) .|> Symbol .|> string
module_isloaded(p::PackageInfo) = module_isloaded(p.name)

"""
    reset()

Resets the `LOAD_PATH` to it's default value of `["@", "@v#.#", "@stdlib"]`, thus removing any manually added paths. 

This function is public, not exported.
"""
function reset()
    default_paths = ["@", "@v#.#", "@stdlib"]
    empty!(LOAD_PATH)
    append!(LOAD_PATH, default_paths)
    return nothing  
end

function askifdelete(p::PackageInfo; loaded)
    if loaded
        info = "Package $(p.name) is currently loaded. Are you sure you want to remove it from the environment(s)?"
        opt_yes = "Yes, remove it."
        opt_no = "SKIPPING removing for now. It is better to restart Julia, then remove it."
    else
        envs = [env.name for env in p.envs]
        info = "Package $(p.name) is present in multiple environments $(envs). Should we remove it from all of them?"
        opt_yes = "Remove from all environments."
        opt_no = "SKIPPING deleting. You can remove it later with the help of Pkg, " *
            """or specify the env in the call, e.g. `ShareAdd.delete("@$(envs[1])"=>"$(p.name)")`, """
    end
    return askifdelete(info, opt_yes, opt_no)
end

function askifdelete(e::EnvInfo)
    info = "Environment $(e.name) is currently in the `LOAD_PATH`. Should we delete it despite that?"
    opt_yes = "Delete"
    opt_no = """SKIPPING deleting. You can delete it later manually by trashing the folder or by calling `ShareAdd.delete("@$(e.name)")`."""
    return askifdelete(info, opt_yes, opt_no)
end

function askifdelete(info::AbstractString, opt_yes::AbstractString, opt_no::AbstractString)
    menu = RadioMenu([opt_yes, opt_no])
    println("Use the arrow keys to move the cursor. Press Enter to select. \n")
    return request(info, menu, ) == 1
end
