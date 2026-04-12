# --- Workspace detection and package lookup for Julia 1.12+ ---

"""
    find_workspace_root(project_file::String) -> Union{Nothing, String}

Find the root `Project.toml` of the workspace containing `project_file`.
Returns `nothing` if `project_file` is not part of any workspace,
or if running on Julia < 1.12.

Walks up the directory tree from `project_file`, looking for a parent
`Project.toml` whose `[workspace].projects` lists a path that resolves
to the directory of `project_file`.  Stops at the filesystem root or
when leaving `homedir()` (if the search started inside it).

Handles nested workspaces by repeating the upward search from each
discovered root.
"""
function find_workspace_root(project_file)
    VERSION >= v"1.12" || return nothing
    
    root = nothing
    if isfile(project_file)
        data = TOML.parsefile(project_file)
        if get(data, "workspace", nothing) isa Dict && get(data["workspace"], "projects", nothing) isa Vector
            root = project_file
        end
    end

    if isnothing(root)
        root = _find_parent_workspace(project_file)
    end
    
    isnothing(root) && return nothing
    
    # Walk up further to handle nested workspaces
    while true
        parent = _find_parent_workspace(root)
        isnothing(parent) && break
        root = parent
    end
    return root
end

"""
    _find_parent_workspace(project_file::String) -> Union{Nothing, String}

Low-level helper: walk up from `project_file` looking for an immediate
parent workspace that lists the project.
"""
function _find_parent_workspace(project_file)
    home_dir = abspath(homedir())
    project_dir = abspath(dirname(project_file))
    current_dir = project_dir
    started_in_home = startswith(project_dir, home_dir)

    while true
        parent_dir = dirname(current_dir)
        # Reached filesystem root
        parent_dir == current_dir && return nothing
        # Left home directory
        started_in_home && !startswith(parent_dir, home_dir) && return nothing

        candidate = _locate_project_file(parent_dir)
        if !isnothing(candidate)
            ws_data = TOML.parsefile(candidate)
            workspace = get(ws_data, "workspace", nothing)
            if workspace isa Dict
                projects = get(workspace, "projects", nothing)
                if projects isa Vector
                    ws_root = dirname(candidate)
                    for proj_rel in projects
                        proj_path = abspath(joinpath(ws_root, proj_rel))
                        if isdir(proj_path) && _samedir(proj_path, project_dir)
                            return candidate
                        end
                    end
                end
            end
        end
        current_dir = parent_dir
    end
end

"Check whether two directory paths refer to the same location."
function _samedir(a, b)
    a = rstrip(abspath(a), ['/', '\\'])
    b = rstrip(abspath(b), ['/', '\\'])
    a == b && return true
    # fall back to inode comparison when available
    try
        return stat(a).inode != 0 && stat(a).inode == stat(b).inode && stat(a).device == stat(b).device
    catch
        return false
    end
end


"""
    workspace_sibling_packages(root_project::String, current_project::String)
        -> Dict{String, String}

Given the path to a workspace root `Project.toml` and the path to the
currently active `Project.toml`, return a `Dict` that maps every package
name reachable through workspace sibling projects to the directory of the
sibling project that provides it.

"Reachable" means the package is either the sibling itself (it has
`name` and `uuid` fields) **or** one of its declared `[deps]`.
Packages that are already in the current project's `[deps]` are excluded.
"""
function workspace_sibling_packages(root_project, current_project)
    result = Dict{String, String}()

    root_dir = dirname(root_project)
    root_data = TOML.parsefile(root_project)

    ws = get(root_data, "workspace", nothing)
    ws isa Dict || return result
    projects = get(ws, "projects", nothing)
    projects isa Vector || return result

    # Current project's own deps – we skip these
    current_data = isfile(current_project) ? TOML.parsefile(current_project) : Dict{String,Any}()
    current_deps = Set{String}(keys(get(current_data, "deps", Dict{String,Any}())))

    current_dir = abspath(dirname(current_project))

    _collect_siblings!(result, root_dir, projects, current_dir, current_deps)

    return result
end

"""
Recursively collect packages from workspace projects into `result`,
skipping the project at `current_dir` and any names already in
`current_deps`.
"""
function _collect_siblings!(result, base_dir,
                            projects, current_dir,
                            current_deps)
    for proj_rel in projects
        proj_rel isa AbstractString || continue
        proj_dir = abspath(joinpath(base_dir, proj_rel))

        proj_file = _locate_project_file(proj_dir)
        isnothing(proj_file) && continue
        sibling_data = TOML.parsefile(proj_file)

        is_current = _samedir(proj_dir, current_dir)

        if !is_current
            # The sibling itself as a package
            sibling_name = get(sibling_data, "name", nothing)
            if sibling_name isa String && !(sibling_name in current_deps) && !haskey(result, sibling_name)
                result[sibling_name] = proj_dir
            end

            # The sibling's declared deps
            for dep_name in keys(get(sibling_data, "deps", Dict{String,Any}()))
                dep_name in current_deps && continue
                haskey(result, dep_name) && continue
                result[dep_name] = proj_dir
            end
        end

        # Nested workspace inside the sibling
        nested_ws = get(sibling_data, "workspace", nothing)
        if nested_ws isa Dict
            nested_projects = get(nested_ws, "projects", nothing)
            if nested_projects isa Vector
                _collect_siblings!(result, proj_dir, nested_projects, current_dir, current_deps)
            end
        end
    end
end

"""
    check_workspace_packages(packages, current_project::String)
        -> (workspace_pkgs::Vector{String}, workspace_paths::Dict{String,String})

Check which of the requested `packages` are available through workspace
siblings of the environment at `current_project`.

Returns a tuple of:
- `workspace_pkgs` – the subset of `packages` found in workspace siblings
- `workspace_paths` – mapping from each such package name to the sibling
  project directory that provides it
"""
function check_workspace_packages(packages, current_project)
    workspace_pkgs = String[]
    workspace_paths = Dict{String, String}()

    root = find_workspace_root(current_project)
    isnothing(root) && return (workspace_pkgs, workspace_paths)

    sibling_pkgs = workspace_sibling_packages(root, current_project)

    for pkg in packages
        if haskey(sibling_pkgs, pkg)
            push!(workspace_pkgs, pkg)
            workspace_paths[pkg] = sibling_pkgs[pkg]
        end
    end

    return (workspace_pkgs, workspace_paths)
end
