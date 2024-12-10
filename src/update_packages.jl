
"""
    update_shared()
    update_shared(nm::AbstractString)
    update_shared(nm::Vector{<:AbstractString})
    update_shared(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}) 
    update_shared(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing) where S <: AbstractString

- Called with no arguments, updates all shared environments.
- Called with a single argument `nm::String` starting with "@", updates the environment `nm` (if it exists).
- Called with a single argument `nm::String` not starting with "@", updates the package `nm` in all shared environments.
- Called with a single argument `nm::Vector{String}`, updates the packages and/or environments in `nm`.
- Called with two arguments `env` and `pkgs`, updates the package(s) `pkgs` in the environment `env`.

Returnes `nothing`.
"""
function update_shared(env::EnvInfo, pkgs::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing) 
    curr_env = current_env()
    Pkg.activate(env.path)
    isnothing(pkgs) ? Pkg.update() : Pkg.update(pkgs)
    Pkg.activate(curr_env.path)
    return nothing
end

versioned_mnf_supported() = VERSION >= v"1.11.0"

function versioned_mnf_name()
    versioned_mnf_supported() || return nothing
    return "Manifest-v$(VERSION.major).$(VERSION.minor).toml"
end

function versioned_mnfs(path)
    rx = r"manifest-v(\d+)\.(\d+)\.toml"
    filenames = readdir(path) .|> lowercase
    mnfs = filter(x -> startswith(x, rx), filenames)
    vs = VersionNumber[]
    for mn in mnfs
        m = match(rx, mn)
        v = VersionNumber("$(m[1]).$(m[2])")
        push!(vs, v)
    end
    ("manifest.toml" in filenames) && push!(vs, v"1.0")
    return vs
end

function has_current_mnf(path)
    versioned_mnf_supported() && return isfile(joinpath(path, versioned_mnf_name()))
    return isfile(joinpath(path, "Manifest.toml"))
end

function update_shared()
    envinfos = shared_environments_envinfos().shared_envs
    for env in envinfos
        update_shared(env)
    end
    return nothing
end

function update_shared(nm::AbstractString; ignore_missing=false)
    isenv = startswith(nm, "@")
    if isenv
        env = getenvinfo(nm)
        update_shared(env)
    else
        packages = list_shared_packages()
        if !haskey(packages, nm) 
            ignore_missing && return # covers the case when the package nm is in the current project and thus available - but not in any shared env
            error("Package $nm not found")
        end

        p = packages[nm]
        for env in p.envs
            update_shared(env, nm)
        end
    end
    return nothing
end

function update_shared(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}) 
    startswith(env, "@") || error("Name of shared environment must start with @")
    update_shared(getenvinfo(env), pkgs)
end

update_shared(nm::Vector{<:AbstractString}; ignore_missing=false) = (update_shared.(nm; ignore_missing); return nothing)

@kwdef mutable struct accepted_kwargs
    update_pkg::Bool = false
    update_env::Bool = false
    update_all::Bool = false
end

function update_if_asked(flags, packages)
    if flags.update_all 
        update_all()
    elseif flags.update_env 
        update_all_envs()
    elseif flags.update_pkg
        update_shared(packages; ignore_missing=true)
    end
    return nothing
end

"updates all shared environments currently in LOAD_PATH"
function update_all_envs()
    (; shared_envs) = shared_environments_envinfos()
    envs = ["@$(env.name)" for env in shared_envs if env.in_path]
    update_shared(envs)
    return nothing
end

"updated all shared environments and the current project"

function update_all()
    Pkg.update()
    update_shared()
    return nothing
end
