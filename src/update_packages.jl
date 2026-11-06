# --- Versioned manifests ---

"Matches versioned manifest file names, e.g. `Manifest-v1.12.toml` (case-insensitive)"
const VERSIONED_MNF_RX = r"^manifest-v(\d+)\.(\d+)\.toml$"i

"Matches `JuliaManifest.toml` and `JuliaManifest-vX.Y.toml` (case-insensitive)"
const JULIA_MNF_RX = r"^juliamanifest(-v\d+\.\d+)?\.toml$"i

versioned_mnf_name(v=VERSION) = "Manifest-v$(v.major).$(v.minor).toml"

minor_version(v::VersionNumber) = VersionNumber(v.major, v.minor)

_normdir(p) = rstrip(normpath(abspath(p)), ['/', '\\'])

"""
    active_mnf_path(env_dir::AbstractString) -> Union{String, Nothing}

Return the path of the manifest which Julia would use for the environment in `env_dir`,
or `nothing` if there is no project file or no manifest. Has no side effects.

Accounts for workspaces, an explicit `manifest` entry in the project file, `JuliaManifest*.toml`,
and versioned manifests, by relying on the internal function `Base.project_file_manifest_path`.
This is the only place where this internal function is called.
"""
function active_mnf_path(env_dir)
    prj = _locate_project_file(env_dir)
    isnothing(prj) && return nothing
    return Base.project_file_manifest_path(String(abspath(prj)))
end

"""
    is_std_env(dir::AbstractString) -> Bool

Check whether `dir` is a standard (version-named) environment like `@v1.12` in the environments folder.
"""
function is_std_env(dir)
    d = _normdir(dir)
    _normdir(dirname(d)) == _normdir(env_folders().envs_folder) || return false
    return !isnothing(tryparse(VersionNumber, basename(d)))
end

"""
    env_mode(dir::AbstractString) -> Symbol

Return `:shared` if `dir` is located directly in the shared environments folder, otherwise `:project`.
"""
function env_mode(dir)
    d = _normdir(dir)
    return _normdir(dirname(d)) == _normdir(env_folders().envs_folder) ? :shared : :project
end

"""
    mnf_target(env_dir::AbstractString) -> @NamedTuple{dir::String, mode::Symbol}

Return the directory whose manifest Pkg actually uses for the environment in `env_dir`,
together with the mode (`:shared` or `:project`) for versioned manifest handling.
For a workspace member, this is the directory of the workspace root, which is always handled as `:project`.
"""
function mnf_target(env_dir)
    prj = something(_locate_project_file(env_dir), joinpath(env_dir, "Project.toml"))
    root = find_workspace_root(prj)
    if !isnothing(root) && _normdir(dirname(root)) != _normdir(env_dir)
        return (; dir = String(dirname(root)), mode = :project)
    end
    return (; dir = String(env_dir), mode = env_mode(env_dir))
end

"""
    scan_mnfs(dir::AbstractString) -> NamedTuple

List manifest files in `dir`, using their actual on-disk names.

Returns `(; versioned::Dict{VersionNumber, String}, generic::Union{Nothing, String}, julia_mnfs::Vector{String})`.
"""
function scan_mnfs(dir)
    versioned = Dict{VersionNumber, String}()
    generic = nothing
    julia_mnfs = String[]
    isdir(dir) || return (; versioned, generic, julia_mnfs)
    for f in readdir(dir)
        isfile(joinpath(dir, f)) || continue
        m = match(VERSIONED_MNF_RX, f)
        if !isnothing(m)
            versioned[VersionNumber(parse(Int, m[1]), parse(Int, m[2]))] = f
        elseif lowercase(f) == "manifest.toml"
            generic = f
        elseif occursin(JULIA_MNF_RX, f)
            push!(julia_mnfs, f)
        end
    end
    return (; versioned, generic, julia_mnfs)
end

"""
    generic_mnf_info(path::AbstractString) -> @NamedTuple{status::Symbol, version::Union{Nothing, VersionNumber}}

Classify a generic manifest file as `:empty`, `:invalid` (not parseable as TOML), or `:valid`.
For valid manifests, `version` is the `major.minor` of its `julia_version` entry, or `v"1.0"` if absent.
"""
function generic_mnf_info(path)
    filesize(path) == 0 && return (; status = :empty, version = nothing)
    d = TOML.tryparsefile(path)
    d isa TOML.ParserError && return (; status = :invalid, version = nothing)
    jv = get(d, "julia_version", nothing)
    v = jv isa AbstractString ? tryparse(VersionNumber, jv) : nothing
    version = isnothing(v) ? v"1.0" : minor_version(v)
    return (; status = :valid, version)
end

"Return a file name in `dir` starting with `base` which does not exist yet."
function free_name(dir, base)
    isfile(joinpath(dir, base)) || return base
    i = 1
    while isfile(joinpath(dir, "$base-$i"))
        i += 1
    end
    return "$base-$i"
end

const MNF_HINT_DELETE = "You may want to delete one of them."

"""
    plan_mnf(dir::AbstractString; v::VersionNumber=VERSION, mode::Symbol=env_mode(dir)) -> NamedTuple

Decide (without modifying any files) how to provide a versioned manifest for Julia version `v` in `dir`.

Returns `(; action, steps, notices, current)`, where
- `action` is one of `:none` (nothing to do), `:skip` (leave the manifests to Pkg), or `:proceed`;
- `steps` is a vector of file operations: `(:rm, f)`, `(:mv, src, dst)`, `(:cp, src, dst)`, `(:touch, f)`
  with file names relative to `dir`;
- `notices` is a vector of `(; level, msg)` with `level ∈ (:info, :warn, :dire)`;
- `current` is the name of the versioned manifest for `v` after the steps, or `nothing`.

In `:project` mode, existing files are never removed or renamed.
"""
function plan_mnf(dir; v=VERSION, mode=env_mode(dir))
    V = minor_version(v)
    dst = versioned_mnf_name(V)
    steps = Tuple[]
    notices = NamedTuple[]
    note!(level, msg) = (push!(notices, (; level, msg)); nothing)
    skipping() = (; action = :skip, steps = Tuple[], notices, current = nothing)

    # rule 0: standard environments like @v1.12 are not versioned
    is_std_env(dir) && return (; action = :none, steps, notices, current = nothing)

    # rule 1a: explicit manifest entry in the project file
    prj = _locate_project_file(dir)
    if !isnothing(prj)
        d = TOML.tryparsefile(prj)
        if d isa TOML.ParserError
            note!(:warn, "Project file $prj could not be parsed. Versioned manifest handling skipped.")
            return skipping()
        elseif haskey(d, "manifest")
            note!(:warn, "Project file $prj specifies a manifest explicitly. Versioned manifest handling skipped in $dir.")
            return skipping()
        end
    end

    (; versioned, generic, julia_mnfs) = scan_mnfs(dir)

    # rule 1b: JuliaManifest*.toml present
    if !isempty(julia_mnfs)
        note!(:warn, "Found $(join(julia_mnfs, ", ")) in $dir. Versioned manifest handling skipped.")
        return skipping()
    end

    has_current = haskey(versioned, V)
    generic_candidate = nothing # (; version, file) of a generic manifest usable as copy source

    if !isnothing(generic)
        gpath = joinpath(dir, generic)
        ginfo = generic_mnf_info(gpath)
        if ginfo.status == :empty # rule 2a
            if mode == :shared
                push!(steps, (:rm, generic))
                note!(:info, "Removed empty $generic in $dir.")
            else
                note!(:info, "Empty $generic in $dir ignored.")
            end
        elseif ginfo.status == :invalid # rule 2b
            if mode == :shared
                newname = free_name(dir, "$generic.invalid")
                push!(steps, (:mv, generic, newname))
                note!(:warn, "$generic in $dir is not a valid TOML file. Renamed to $newname.")
            else
                note!(:warn, "$generic in $dir is not a valid TOML file. Versioned manifest handling skipped.")
                return skipping()
            end
        else
            G = ginfo.version
            if haskey(versioned, G) # rule 3
                vfile = versioned[G]
                if read(gpath) == read(joinpath(dir, vfile)) # rule 3a
                    if mode == :shared
                        push!(steps, (:rm, generic))
                        note!(:warn, "$generic in $dir was identical to $vfile and has been removed.")
                    else
                        note!(:info, "$generic and $vfile in $dir are identical. $MNF_HINT_DELETE")
                    end
                else
                    sources = filter(<=(V), vcat(collect(keys(versioned)), G))
                    if !has_current && !isempty(sources) && G == maximum(sources) # rule 3b
                        act = mode == :shared ? "renaming" : "copying"
                        note!(:dire, "$generic and $vfile in $dir are both for Julia v$(G.major).$(G.minor), " *
                            "but differ. ShareAdd cannot decide which one to use for Julia v$(V.major).$(V.minor), " *
                            "and relegates versioned manifest handling to Pkg, which will presumably update $generic, " *
                            "with ShareAdd subsequently $act the resulting manifest into $dst. " *
                            "In doubt, please review the outcome.")
                        return skipping()
                    elseif G == V # rule 3c
                        note!(:warn, "$generic and $vfile in $dir differ. $generic is ignored by Julia " *
                            "v$(V.major).$(V.minor). $MNF_HINT_DELETE")
                    elseif !has_current # rule 3d
                        note!(:info, "$generic and $vfile in $dir are both for Julia v$(G.major).$(G.minor), but differ.")
                    end
                end
            elseif G >= v"1.10" # rule 4
                if mode == :shared
                    newname = versioned_mnf_name(G)
                    push!(steps, (:mv, generic, newname))
                    versioned[G] = newname
                    note!(:info, "Renamed $generic to $newname in $dir.")
                elseif G <= V
                    generic_candidate = (; version = G, file = generic)
                end
            else # G < v"1.10"
                generic_candidate = (; version = G, file = generic)
            end
        end
    end

    # rule 5
    haskey(versioned, V) && return (; action = :proceed, steps, notices, current = versioned[V])

    # rule 6: copy forward from the most recent manifest not newer than V
    candidates = [(; version = k, file = f) for (k, f) in versioned if k < V]
    isnothing(generic_candidate) || push!(candidates, generic_candidate)
    if isempty(candidates)
        push!(steps, (:touch, dst))
    else
        src = argmax(c -> c.version, candidates)
        push!(steps, (:cp, src.file, dst))
        if src === generic_candidate && mode == :project
            note!(:info, "Copied $(src.file) to $dst in $dir. Now there are two identical manifests. $MNF_HINT_DELETE")
        else
            note!(:info, "Copied $(src.file) to $dst in $dir.")
        end
    end
    return (; action = :proceed, steps, notices, current = dst)
end

"Copy `src` to `dst` (both absolute paths) via a temporary file, so that `dst` never exists half-written."
function atomic_cp(src, dst)
    tmp = tempname(dirname(dst); cleanup=false)
    try
        cp(src, tmp)
        mv(tmp, dst)
    finally
        ispath(tmp) && rm(tmp)
    end
    return dst
end

"""
    apply_mnf_plan!(dir::AbstractString, plan::NamedTuple) -> Union{String, Nothing}

Execute the file operations of a `plan` returned by [`plan_mnf`](@ref) in `dir`, then report its notices.

Returns the path of the versioned manifest for the current Julia version, the active manifest for `:none`,
or `nothing` for `:skip`.
"""
function apply_mnf_plan!(dir, plan)
    if plan.action == :proceed
        for st in plan.steps
            op = st[1]
            if op == :rm
                rm(joinpath(dir, st[2]))
            elseif op == :mv
                mv(joinpath(dir, st[2]), joinpath(dir, st[3]))
            elseif op == :cp
                atomic_cp(joinpath(dir, st[2]), joinpath(dir, st[3]))
            elseif op == :touch
                touch(joinpath(dir, st[2]))
            else
                error("Unknown manifest operation $op")
            end
        end
    end
    foreach(n -> report_notice!(n.level, n.msg), plan.notices)
    plan.action == :none && return active_mnf_path(dir)
    plan.action == :skip && return nothing
    return joinpath(dir, plan.current)
end

"""
    make_current_mnf(path_or_name::AbstractString) -> Union{String, Nothing}
    make_current_mnf(; current::Bool) -> Union{String, Nothing}
    make_current_mnf(env::EnvInfo) -> Union{String, Nothing}

Creates a [versioned manifest](https://pkgdocs.julialang.org/v1/toml-files/#Different-Manifests-for-Different-Julia-versions)
for the currently running Julia version, e.g. `Manifest-v1.12.toml`.

If called `make_current_mnf(; current=true)`, the current environment will be processed by this function. 

`path_or_name` can name of a shared environment starting with `@`, or a path to any environment.
For a member of a workspace, the workspace root is processed.

- If the environment is a standard environment (e.g. "@v1.12"), do nothing.
- If the project file specifies a manifest explicitly, or a `JuliaManifest*.toml` file exists, do nothing and warn.
- If a versioned manifest for current Julia already exists, keep it.
- Else, if a manifest for an older Julia exists, copy the most recent one to the versioned manifest for the current Julia.
- Else, create an empty one.

In shared environments, a generic `Manifest.toml` is tidied up: if empty, it is deleted; if invalid, it is renamed to
`Manifest.toml.invalid`; if identical to a versioned manifest for the same Julia version, it is deleted;
if created by Julia v1.10 or later and no versioned counterpart exists, it is renamed into a versioned manifest.
In other environments (projects), existing files are never deleted or renamed.

If a generic and a versioned manifest for the same Julia version differ, and it is not clear which one to use,
nothing is done and a warning is issued.

Returns path to the created or existing versioned manifest, or `nothing` if nothing was done because of a conflict.
For standard environments, returns the path of the active manifest (or `nothing`).

This function is public, not exported.
"""
function make_current_mnf(p)
    startswith(p, "@") && (p = env_path(p))
    isdir(p) || error("Path $p is not a directory")
    (; dir, mode) = mnf_target(p)
    isdir(dir) || error("Path $dir is not a directory")
    plan = plan_mnf(dir; mode)
    return apply_mnf_plan!(dir, plan)
end

make_current_mnf(env::EnvInfo) = make_current_mnf(env.path)

function make_current_mnf(; current::Bool)
    current || return nothing
    curr_env = current_env()
    return make_current_mnf(curr_env)
end

"""
    prep_mnf_safely(env_dir::AbstractString) -> Nothing

Call [`make_current_mnf`](@ref) on `env_dir` (if it exists), reporting any error as a notice instead of throwing.
"""
function prep_mnf_safely(env_dir)
    isdir(env_dir) || return nothing
    try
        make_current_mnf(env_dir)
    catch e
        e isa InterruptException && rethrow()
        report_notice!(:warn, "Error preparing versioned manifest in $env_dir: $(sprint(showerror, e))")
    end
    return nothing
end

"""
    with_versioned_mnf(f::Function, env_dir::AbstractString; enabled::Bool=true) -> Any

Run `f()` (typically a `Pkg.add` or `Pkg.update` in the environment `env_dir`), preparing the versioned manifest
before, and normalizing it afterwards (also if `f` throws). Returns the result of `f()`.

If the manifests are ambiguous, they are left untouched before `f()`, so that Pkg decides which one to use.
If `enabled=false`, just runs `f()`.
"""
function with_versioned_mnf(f, env_dir; enabled=true)
    enabled || return f()
    prep_mnf_safely(env_dir)
    try
        return f()
    finally
        prep_mnf_safely(env_dir)
    end
end

"Task-local storage key used by `with_update_tracking` to collect failed update targets"
const TASK_KEY_FAILED_UPDATES = :shareadd_failed_updates

"Task-local storage key used by `with_update_tracking` to collect notices"
const TASK_KEY_NOTICES = :shareadd_notices

const NOTICE_LEVELS = (:dire, :warn, :info)

"Emit a notice immediately as a log message."
function emit_notice(level, msg)
    if level == :dire
        @warn "ATTENTION! " * msg
    elseif level == :warn
        @warn msg
    else
        @info msg
    end
    return nothing
end

"""
    report_notice!(level::Symbol, msg::AbstractString) -> Nothing

Report a notice with `level ∈ (:info, :warn, :dire)`. Within a [`with_update_tracking`](@ref) context
the notice is collected and shown at the end, otherwise it is emitted immediately.
"""
function report_notice!(level, msg)
    level in NOTICE_LEVELS || error("Unknown notice level $level")
    tls = task_local_storage()
    if haskey(tls, TASK_KEY_NOTICES)
        push!(tls[TASK_KEY_NOTICES], (; level, msg = String(msg)))
    else
        emit_notice(level, msg)
    end
    return nothing
end

"Emit collected notices, deduplicated and ordered by severity."
function emit_notices(notices)
    unique!(notices)
    for level in NOTICE_LEVELS
        for n in notices
            n.level == level && emit_notice(n.level, n.msg)
        end
    end
    return nothing
end

"""
    with_update_tracking(f::Function)

Execute `f()` within a reentrant error-tracking context. If an outer tracking context is
already active, `f()` is executed directly. Otherwise, captures any update errors reported via
[`record_update_error!`](@ref) and notices reported via [`report_notice!`](@ref). Upon completion,
emits the collected notices, followed by a single consolidated `@warn` summary of the errors.
"""
function with_update_tracking(f)
    if haskey(task_local_storage(), TASK_KEY_FAILED_UPDATES)
        return f()
    end
    failures = String[]
    notices = NamedTuple{(:level, :msg), Tuple{Symbol, String}}[]
    task_local_storage(TASK_KEY_FAILED_UPDATES, failures)
    task_local_storage(TASK_KEY_NOTICES, notices)
    try
        return f()
    finally
        delete!(task_local_storage(), TASK_KEY_FAILED_UPDATES)
        delete!(task_local_storage(), TASK_KEY_NOTICES)
        emit_notices(notices)
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
    update(; versioned_mnf=true)
    update(nm::AbstractString; warn_if_missing=false, versioned_mnf=true)
    update(nm::Vector{<:AbstractString}; warn_if_missing=true, versioned_mnf=true)
    update(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}; warn_if_missing=true, versioned_mnf=true) 
    update(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing; warn_if_missing=false, versioned_mnf=true) where S <: AbstractString
    update(p::Pair{<:AbstractString, <:AbstractString}; warn_if_missing=false, versioned_mnf=true)

- Called without arguments, updates all shared environments.
- Called with a single argument `nm::String` starting with "@", updates the shared environment `nm`.
- Called with a single argument `nm::String` not starting with "@", updates the package `nm` 
    in all shared environments containing the package, as well as all it's downstream dependencies.
- Called with a single argument `nm::Vector{String}`, updates the packages and/or environments in `nm`.
- Called with two arguments `env` and `pkgs`, updates the package(s) `pkgs` in the environment `env`.
- Called with an argument `env => pkg`, updates the package `pkg` in the environment `env`.

# Keyword Arguments
- `warn_if_missing::Bool=true` - if env or pkg not found, issues a warning, otherwise would throw an error
- `versioned_mnf::Bool=true` - if `true`, a versioned manifest will be created or maintained in each updated env.

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
function update(env::EnvInfo, pkgs::Union{Nothing,AbstractString,Vector{<:AbstractString}}=nothing; warn_if_missing=true, versioned_mnf=true)
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

        if !isnothing(updatable_pkgs) && !isempty(updatable_pkgs)
            try
                with_versioned_mnf(env.path; enabled=versioned_mnf) do
                    Pkg.activate(env.path)
                    if isnothing(pkgs_vec)
                        Pkg.update()
                    else
                        Pkg.update(updatable_pkgs; preserve=PRESERVE_NONE)
                    end
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

function update(; versioned_mnf=true)
    with_update_tracking() do
        envinfos = shared_environments_envinfos().shared_envs
        for env in envinfos |> values
            update(env; versioned_mnf)
        end
    end
    return nothing
end

# if just one name is specified, would normally throw an error if not found
function update(nm::AbstractString; warn_if_missing=false, versioned_mnf=true)
    with_update_tracking() do
        isenv = startswith(nm, "@")
        if isenv
            env = getenvinfo(nm)
            update(env; warn_if_missing, versioned_mnf)
        else
            update_package(nm; warn_if_missing, versioned_mnf)
        end
    end
    return nothing
end

# if just one name is specified, would normally throw an error if not found
function update(env::AbstractString, pkgs::Union{AbstractString,Vector{<:AbstractString}}; warn_if_missing=false, versioned_mnf=true)
    startswith(env, "@") || error("Name of shared environment must start with @")
    with_update_tracking() do
        update(EnvInfo(env), pkgs; warn_if_missing, versioned_mnf)
    end
    return nothing
end

update(nm::Vector{<:AbstractString}; warn_if_missing=true, versioned_mnf=true) =
    (with_update_tracking(() -> update.(nm; warn_if_missing, versioned_mnf)); return nothing)

update(p::Pair{<:AbstractString,<:AbstractString}; warn_if_missing=false, versioned_mnf=true) =
    update(p.first, p.second; warn_if_missing, versioned_mnf)

function update_package(nm; warn_if_missing, versioned_mnf=true)
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
            with_versioned_mnf(curr_env.path; enabled=versioned_mnf) do
                Pkg.update(nm)
            end
        catch e
            target_str = env_target(curr_env, nm)
            @warn "Error updating $target_str" exception=e
            record_update_error!(target_str)
        end
    end

    if in_shared
        p = packages[nm]
        for env in p.envs
            update(env, nm; versioned_mnf)
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
            with_versioned_mnf(curr_env.path) do
                Pkg.update()
            end
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