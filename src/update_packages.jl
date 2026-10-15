versioned_mnf_supported(v=VERSION) = v >= v"1.10.8"

function versioned_mnf_name(v=VERSION)
    versioned_mnf_supported() || return nothing
    return "Manifest-v$(v.major).$(v.minor).toml"
end

function versioned_mnfs(path)
    rx = r"^manifest-v(\d+)\.(\d+)\.toml$"
    filenames = readdir(path) .|> lowercase
    mnfs = filter(x -> occursin(rx, x), filenames)
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
    main_env_name() == (path|>abspath|>splitpath)[end] |> lowercase

function has_current_mnf(path)
    isdir(path) || return nothing
    is_main_env(path) && return true
    versioned_mnf_supported() && return isfile(joinpath(path, versioned_mnf_name()))
    return isfile(joinpath(path, "Manifest.toml"))
end

function current_mnf(path)
    isdir(path) || return nothing
    (is_main_env(path) || !versioned_mnf_supported()) &&
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
    p = joinpath(path, versioned_mnf_name()) |> touch
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

"Task-local storage key used by `with_update_tracking` to collect failed update targets"
const TASK_KEY_FAILED_UPDATES = :shareadd_failed_updates

"""
    with_update_tracking(f::Function)

Execute `f()` within a reentrant error-tracking context. If an outer tracking context is
already active, `f()` is executed directly. Otherwise, captures any update errors reported via
[`record_update_error!`](@ref) and emits a single consolidated `@warn` summary upon completion.
"""
function with_update_tracking(f)
    if haskey(task_local_storage(), TASK_KEY_FAILED_UPDATES)
        return f()
    end
    failures = String[]
    task_local_storage(TASK_KEY_FAILED_UPDATES, failures)
    try
        return f()
    finally
        delete!(task_local_storage(), TASK_KEY_FAILED_UPDATES)
        if !isempty(failures)
            unique!(failures)
            target_str = length(failures) == 1 ? "1 target" : "$(length(failures)) targets"
            @warn "Update encountered errors (scroll REPL output for details)\n in $target_str:\n  - " * join(failures, "\n  - ")
        end
    end
end

"""
    record_update_error!(target::AbstractString) -> Nothing

Record a failed update `target` description in the current task's tracking context.
Requires an active [`with_update_tracking`](@ref) context.
"""
function record_update_error!(target)
    @assert haskey(task_local_storage(), TASK_KEY_FAILED_UPDATES) "record_update_error! called outside of with_update_tracking context"
    push!(task_local_storage()[TASK_KEY_FAILED_UPDATES], target)
    return nothing
end

env_name_str(env::EnvInfo) = env.shared ? "@$(env.name)" : "$(env.name) ($(env.path))"

"""
    env_target(env::EnvInfo, pkgs=nothing) -> String

Format a target description for update operations on `env` and optional package(s).
"""
function env_target(env::EnvInfo, pkgs=nothing)
    if isnothing(pkgs) || isempty(pkgs)
        return "environment $(env_name_str(env))"
    elseif pkgs isa AbstractString
        return "environment $(env_name_str(env)) for package $pkgs"
    else
        return "environment $(env_name_str(env)) for package(s) $(join(pkgs, ", "))"
    end
end

"""
    update()
    update(nm::AbstractString; warn_if_missing=false)
    update(nm::Vector{<:AbstractString}; warn_if_missing=true)
    update(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}; warn_if_missing=true) 
    update(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing; warn_if_missing=false) where S <: AbstractString
    update(p::Pair{<:AbstractString, <:AbstractString}; warn_if_missing=false)

- Called without arguments, updates all shared environments.
- Called with a single argument `nm::String` starting with "@", updates the shared environment `nm`.
- Called with a single argument `nm::String` not starting with "@", updates the package `nm` 
    in all shared environments containing the package, as well as all it's downstream dependencies.
- Called with a single argument `nm::Vector{String}`, updates the packages and/or environments in `nm`.
- Called with two arguments `env` and `pkgs`, updates the package(s) `pkgs` in the environment `env`.
- Called with an argument `env => pkg`, updates the package `pkg` in the environment `env`.

# Keyword Arguments
- `warn_if_missing::Bool=true` - if env or pkg not found, issues a warning, otherwise would throw an error

If Julia version supports version-specific manifest, then on any updates a versioned manifest will be created in each updated env.
See also [`make_current_mnf`](@ref).

Errors encountered during updates (e.g. from `Pkg.update` or manifest preparation) are caught and logged as warnings with exception details, allowing updates of remaining environments and packages to proceed without interruption. If any errors occurred across the operation, a single consolidated `@warn` summary listing all failed targets is emitted upon completion.

Returns `nothing`.

# Examples
```julia-repl
julia> ShareAdd.update("@StatPackages")
julia> ShareAdd.update("@Foo" => "bar")
```

This function is public, not exported.
"""
function update(env::EnvInfo, pkgs::Union{Nothing,AbstractString,Vector{<:AbstractString}}=nothing; warn_if_missing=true)
    with_update_tracking() do
        curr_env = current_env()

        pkgs_vec = isnothing(pkgs) ? nothing : (typeof(pkgs) <: AbstractString ? [pkgs] : pkgs)
        if !isnothing(pkgs_vec)
            missing_pkgs = setdiff(pkgs_vec, env.pkgs)
            updatable_pkgs = intersect(pkgs_vec, env.pkgs)
            if !isempty(missing_pkgs)
                errinfo = "Packages $(missing_pkgs) are not in the environment $(env.name)"
                warn_if_missing || error(errinfo)
                @warn errinfo
            end
        else
            updatable_pkgs = env.pkgs
        end

        # Warn about unregistered packages
        unreg = filter(p -> !is_registered(p), collect(updatable_pkgs))
        if !isempty(unreg)
            sort!(unreg)
            @warn "The following packages in @$(env.name) are not registered and cannot be updated by this function: $unreg"
        end

        try
            make_current_mnf(env)
        catch e
            target_str = "manifest for $(env_name_str(env))"
            @warn "Error preparing $target_str" exception=e
            record_update_error!(target_str)
        end

        if !isnothing(updatable_pkgs) && !isempty(updatable_pkgs)
            try
                Pkg.activate(env.path)
                if isnothing(pkgs_vec)
                    Pkg.update()
                else
                    Pkg.update(updatable_pkgs; preserve=PRESERVE_NONE)
                end
            catch e
                target = env_target(env, isnothing(pkgs_vec) ? nothing : updatable_pkgs)
                @warn "Error updating $target" exception=e
                record_update_error!(target)
            finally
                Pkg.activate(curr_env.path)
            end

        end
    end
    return nothing
end

function update()
    with_update_tracking() do
        envinfos = shared_environments_envinfos().shared_envs
        for env in envinfos |> values
            update(env)
        end
    end
    return nothing
end

# if just one name is specified, would normally throw an error if not found
function update(nm::AbstractString; warn_if_missing=false)
    with_update_tracking() do
        isenv = startswith(nm, "@")
        if isenv
            env = getenvinfo(nm)
            update(env; warn_if_missing)
        else
            update_package(nm; warn_if_missing)
        end
    end
    return nothing
end

# if just one name is specified, would normally throw an error if not found
function update(env::AbstractString, pkgs::Union{AbstractString,Vector{<:AbstractString}}; warn_if_missing=false)
    startswith(env, "@") || error("Name of shared environment must start with @")
    with_update_tracking() do
        update(EnvInfo(env), pkgs; warn_if_missing)
    end
    return nothing
end

update(nm::Vector{<:AbstractString}; warn_if_missing=true) =
    (with_update_tracking(() -> update.(nm; warn_if_missing)); return nothing)

update(p::Pair{<:AbstractString,<:AbstractString}; warn_if_missing=false) = update(p.first, p.second; warn_if_missing)

function update_package(nm; warn_if_missing)
    packages = list_shared_packages()
    curr_env = current_env()

    in_curr = nm in curr_env.pkgs || nm == curr_env.name
    in_shared = haskey(packages, nm)

    if !in_curr && !in_shared
        warn_if_missing && (@warn "Package $nm not found"; return nothing)
        error("Package $nm not found")
    end

    if in_curr
        try
            make_current_mnf(; current=true)
        catch e
            target_str = "manifest for $(env_name_str(curr_env))"
            @warn "Error preparing $target_str" exception=e
            record_update_error!(target_str)
        end
        try
            Pkg.update(nm)
        catch e
            target_str = env_target(curr_env, nm)
            @warn "Error updating $target_str" exception=e
            record_update_error!(target_str)
        end
    end

    if in_shared
        p = packages[nm]
        for env in p.envs
            update(env, nm)
        end
    end
end

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
    with_update_tracking() do
        curr_env = current_env()
        try
            make_current_mnf(; current=true)
        catch e
            target_str = "manifest for $(env_name_str(curr_env))"
            @warn "Error preparing $target_str" exception=e
            record_update_error!(target_str)
        end
        try
            Pkg.update()
        catch e
            target_str = env_target(curr_env)
            @warn "Error updating $target_str" exception=e
            record_update_error!(target_str)
        end
        update()
    end
    return nothing
end

"Removes folders created in the ~/.julia/environments/ folder during the testing. Used in the test suite, but also on the package startup just for the case the test errored."
function cleanup_testenvs()
    (; envs_folder) = env_folders()
    isdir(envs_folder) || return nothing
    for f in readdir(envs_folder, join=true)
        startswith(basename(f), testfolder_prefix) && rm(f, recursive=true)
    end
    return nothing
end