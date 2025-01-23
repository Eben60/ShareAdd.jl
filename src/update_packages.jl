versioned_mnf_supported(v = VERSION) = v >= v"1.10.8"

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

is_main_env(path) = 
    "v$(VERSION.major).$(VERSION.minor)" == (path |> abspath |> splitpath)[end] |> lowercase

function has_current_mnf(path)
    isdir(path) || return nothing
    is_main_env(path) && return true
    versioned_mnf_supported() && return isfile(joinpath(path, versioned_mnf_name()))
    return isfile(joinpath(path, "Manifest.toml"))
end

function current_mnf(path)
    isdir(path) || return nothing
    (is_main_env(path) || ! versioned_mnf_supported() ) && 
        return joinpath(path, "Manifest.toml")
    return joinpath(path, versioned_mnf_name())
end

function copy_mnf(path)
    mnfs = versioned_mnfs(path)
    i = searchsortedlast(mnfs, VERSION)
    i == 0 && (create_empty_mnf(path); return nothing)
    src_mnf = joinpath(path, mnfs[i] == v"1.0" ? "Manifest.toml" : versioned_mnf_name(mnfs[i]))
    dst_mnf = joinpath(path, versioned_mnf_name())
    cp(src_mnf, dst_mnf)
    return dst_mnf
end

function create_empty_mnf(path) 
    p = joinpath(path, versioned_mnf_name()) |> touch; 
    return p
end

"""
    make_current_mnf(path_or_name) -> path
    make_current_mnf(; current::Bool) -> path
    make_current_mnf(env::EnvInfo) -> path

Creates a [versioned manifest](https://pkgdocs.julialang.org/v1/toml-files/#Different-Manifests-for-Different-Julia-versions)

If called `make_current_mnf(; current=true)`, the current environment will be processed by this function. 

`path_or_name` can name of a shared environment starting with `@`, or a path to any environment.

- If currently executed Julia version doesn't support version-specific manifests, do nothing.
- Else, if a versioned manifest for current Julia already exists, do nothing.
- Else, if the environment is the main shared env for the current Julia version (e.g. "@v1.11" for Julia v1.11), do nothing.
- Else, is a (versioned) manifest for an older Julia exists in the given directory, copy it to a file named according to the current Julia version, e.g. `Manifest-v1.11.toml`.
- Else, create empty one.

Returns path to the created or existing manifest.

This function is public, not exported.
"""
function make_current_mnf(p)
    startswith(p, "@") && (p = env_path(p))
    isdir(p) || error("Path $p is not a directory")
    versioned_mnf_supported() || return current_mnf(p)
    has_current_mnf(p) && return current_mnf(p)
    mnfs = versioned_mnfs(p)
    length(mnfs) == 0 && return create_empty_mnf(p) 
    return copy_mnf(p) 
end

make_current_mnf(env::EnvInfo) = make_current_mnf(env.path)

function make_current_mnf(; current::Bool)
    current || return nothing
    curr_env = current_env()
    return make_current_mnf(curr_env)
end

"""
    update()
    update(nm::AbstractString)
    update(nm::Vector{<:AbstractString})
    update(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}) 
    update(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing) where S <: AbstractString
    update(p::Pair{<:AbstractString, <:AbstractString})

- Called with no arguments, updates all shared environments.
- Called with a single argument `nm::String` starting with "@", updates the shared environment `nm`.
- Called with a single argument `nm::String` not starting with "@", updates the package `nm` in all shared environments.
- Called with a single argument `nm::Vector{String}`, updates the packages and/or environments in `nm`.
- Called with two arguments `env` and `pkgs`, updates the package(s) `pkgs` in the environment `env`.
- Called with an argument env => pkg, updates the package `pkg` in the environment `env`.

If Julia version supports version-specific manifest, then on any updates a versioned manifest will be created in each updated env.
See also [`make_current_mnf`](@ref).

Returnes `nothing`.

# Examples
```julia-repl
julia> ShareAdd.update("@StatPackages")
julia> ShareAdd.update("@Foo" => "bar")
```

This function is public, not exported.
"""
function update(env::EnvInfo, pkgs::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing; warn_if_missing=true) 
    curr_env = current_env()

    if !isnothing(pkgs)
        pkgs = typeof(pkgs) <: AbstractString ? [pkgs] : pkgs
        missing_pkgs = setdiff(pkgs, env.pkgs)
        updatable_pkgs = intersect(pkgs, env.pkgs)
        if !isempty(missing_pkgs)
            errinfo = "Packages $(missing_pkgs) are not in the environment $(env.name)"
            warn_if_missing || error(errinfo)
            @warn errinfo
        end
    else
        updatable_pkgs = env.pkgs
    end

    make_current_mnf(env)

    if !isnothing(updatable_pkgs) && !isempty(updatable_pkgs)
        try
            Pkg.activate(env.path)
            if isnothing(pkgs) 
                Pkg.update()
            else
                Pkg.update(updatable_pkgs)
            end
        catch e
            Pkg.activate(curr_env.path)
            rethrow(e)
        finally
            Pkg.activate(curr_env.path)
        end

    end
    return nothing
end

function update()
    envinfos = shared_environments_envinfos().shared_envs
    for env in envinfos |> values
        update(env)
    end
    return nothing
end

function update(nm::AbstractString; warn_if_missing=false)
    isenv = startswith(nm, "@")
    if isenv
        env = getenvinfo(nm)
        update(env)
    else
        packages = list_shared_packages()
        if !haskey(packages, nm) 
            warn_if_missing && (@warn "Package $nm not found" ;return nothing)
            error("Package $nm not found")
        end

        p = packages[nm]
        for env in p.envs
            update(env, nm)
        end
    end
    return nothing
end

function update(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}; warn_if_missing=false) 
    startswith(env, "@") || error("Name of shared environment must start with @")
    update(EnvInfo(env), pkgs; warn_if_missing)
end

update(nm::Vector{<:AbstractString}; warn_if_missing=true) = (update.(nm; warn_if_missing); return nothing)

update(p::Pair{<:AbstractString, <:AbstractString}; warn_if_missing=true) = update(p.first, p.second; warn_if_missing)

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
        update(packages; warn_if_missing=true)
    end
    return nothing
end

"updates all shared environments currently in LOAD_PATH"
function update_all_envs()
    (; shared_envs) = shared_environments_envinfos()
    envs = ["@$(env.name)" for env in values(shared_envs) if env.in_path]
    update(envs)
    return nothing
end

"updated all shared environments and the current project"
function update_all()
    make_current_mnf(; current=true)
    Pkg.update()
    update()
    return nothing
end
