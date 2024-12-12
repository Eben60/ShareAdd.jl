versioned_mnf_supported(v = VERSION) = v >= v"1.11.0"

function versioned_mnf_name(v = VERSION)
    versioned_mnf_supported() || return nothing
    return "Manifest-v$(v.major).$(v.minor).toml"
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
    sort!(vs)
    return vs
end

function has_current_mnf(path)
    isdir(path) || return nothing

    "v$(VERSION.major).$(VERSION.minor)" == 
        (path |> abspath |> splitpath)[end] |> lowercase && # this is the "main" environment
        return true

    versioned_mnf_supported() && return isfile(joinpath(path, versioned_mnf_name()))
    return isfile(joinpath(path, "Manifest.toml"))
end

function copy_mnf(path)
    mnfs = versioned_mnfs(path)
    i = searchsortedlast(mnfs, VERSION)
    i == 0 && (create_empty_mnf(path); return nothing)
    src_mnf = joinpath(path, mnfs[i] == v"1.0" ? "Manifest.toml" : versioned_mnf_name(mnfs[i]))
    dst_mnf = joinpath(path, versioned_mnf_name())
    cp(src_mnf, dst_mnf)
    return nothing
end

create_empty_mnf(path) = (joinpath(path, versioned_mnf_name()) |> touch; println("touch"); return nothing)

"""
    make_current_mnf(path_or_name)
    make_current_mnf(env::EnvInfo)
    make_current_mnf(; current::Bool)

If called `make_current_mnf(; current=true)`, the current environment will be processed by this function. 

`path_or_name` can name of a shared environment starting with `@`, or a path to any environment.

- If currently executed Julia version doesn't support versioned manifests, do nothing.
- Else, if a versioned manifest for current Julia already exists, do nothing.
- Else, is a (versioned) manifest for an older Julia exists in the given directory, copy it to a file 
named according to the current Julia version, e.g. `Manifest-v1.11.toml`.
- Else, create empty one.
"""
function make_current_mnf(p)
    startswith(p, "@") && (p = env_path(p))
    isdir(p) || error("Path $p is not a directory")
    versioned_mnf_supported() || return nothing
    has_current_mnf(p) && return nothing
    mnfs = versioned_mnfs(p)
    length(mnfs) == 0 && return create_empty_mnf(p)
    copy_mnf(p)
    return nothing
end

make_current_mnf(env::EnvInfo) = make_current_mnf(env.path)

function make_current_mnf(; current::Bool)
    current || return nothing
    curr_env = current_env()
    return make_current_mnf(curr_env)
end

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

If Julia version supports versioned manifests, on any updates, a versioned manifest will be created in each updated env.
See also [`make_current_mnf`](@ref).

Returnes `nothing`.
"""
function update_shared(env::EnvInfo, pkgs::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing) 
    curr_env = current_env()

    make_current_mnf(env) 
    Pkg.activate(env.path)
    isnothing(pkgs) ? Pkg.update() : Pkg.update(pkgs)
    
    Pkg.activate(curr_env.path)
    return nothing
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

@kwdef mutable struct AcceptedKwargs
    update_pkg::Bool = false
    update_env::Bool = false
    update_all::Bool = false
end
Base.:NamedTuple(a::AcceptedKwargs) = NamedTuple([nm => getfield(a, nm) for nm in fieldnames(AcceptedKwargs)])
Base.:(==)(a::AcceptedKwargs, b::AcceptedKwargs) = NamedTuple(a) == NamedTuple(b)

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
    make_current_mnf(; current=true)
    Pkg.update()
    update_shared()
    return nothing
end
