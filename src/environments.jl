
is_minor_version(v1::VersionNumber, v2::VersionNumber) = 
    v1.major == v2.major && v1.minor == v2.minor

"""
    list_shared_environments(depot = first(DEPOT_PATH)) -> (shared_envs::Vector{EnvInfo}, env_path::String)
"""
function list_shared_environments(; depot = first(DEPOT_PATH))
    envs_folder_path = joinpath(depot, "environments")
    j_env = nothing
    shared_envs = EnvInfo[]

    if !isdir(envs_folder_path)
        return String[]
    else
        env_dirlist = readdir(envs_folder_path)
        envs = [s for s in env_dirlist if isdir(joinpath(envs_folder_path, s))]
        for env in envs
            in_path = ("@$(env)" in LOAD_PATH)
            v = tryparse(VersionNumber, env) 
            if !isnothing(v) 
                if is_minor_version(VERSION, v) 
                    in_path = true
                else
                    continue
                end
            end
            path = joinpath(envs_folder_path, env)
            pkgs = list_env_pkgs(path)
            envinfo = EnvInfo(; name = env, path, pkgs, in_path)
            push!(shared_envs, envinfo)
        end

        !isnothing(j_env) && push!(shared_envs, j_env)
        shared_env_names = [s.name for s in shared_envs]
        return (; shared_envs, envs_folder_path, shared_env_names)
    end
end
export list_shared_environments

"""
    list_shared_packages(;depot = first(DEPOT_PATH)) -> Dict{String, PackageInfo}
"""
function list_shared_packages(; depot = first(DEPOT_PATH))
    (; shared_envs, ) = list_shared_environments(; depot)
    packages = Dict{String, PackageInfo}()
    for env in shared_envs
        prs = shared_packages(env.name; depot, skipfirstchar = false)
        for pr in prs
            if !haskey(packages, pr)
                p = PackageInfo(pr, [env], env.in_path)
                p.in_path && empty!(p.envs) # if it is already in path, it doesn't matter which env it is
                packages[pr] = p
            else
                push!(packages[pr].envs, env)
                packages[pr].in_path |= env.in_path
                packages[pr].in_path && empty!(packages[pr].envs)
            end
        end
    end

    # add packages in @stdlib
    std_pcks = stdlib_packages()
    for pk in std_pcks
        packages[pk] = PackageInfo(pk, EnvInfo[], true)
    end
    return packages
end
export list_shared_packages

function env_path(env_name::AbstractString, depot = first(DEPOT_PATH); skipfirstchar = true)
    skipfirstchar && (env_name = env_name[2:end])
    return joinpath(depot, "environments", env_name) 
end

function is_shared_environment(env_name::AbstractString, depot = first(DEPOT_PATH)) 
    startswith(env_name, "@") || error("Environment name must start with @")
    return env_path(env_name, depot) |> isdir
end 
export is_shared_environment

"""
    sh_add(env_name::AbstractString; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) -> Vector{String}

Add shared environment(s) to `LOAD_PATH`, making the corresponding packages all available in the current session.

Returns the list of all packages in the added environments as a `Vector{String}`.

# Examples
```julia-repl
julia> sh_add("@StatPackages")
3-element Vector{String}:
 "Arrow"
 "CSV"
 "DataFrames"

julia> sh_add(["@StatPackages", "@Makie"])
4-element Vector{String}:
 "Arrow"
 "CSV"
 "DataFrames"
 "Makie"

julia> sh_add("@StatPackages", "@Makie")
4-element Vector{String}:
 "Arrow"
 "CSV"
 "DataFrames"
 "Makie"
```
"""
function sh_add(env_name::AbstractString; depot = first(DEPOT_PATH))
    is_shared_environment(env_name, depot) || error("Environment $env_name is not a shared environment")
    env_name in LOAD_PATH || push!(LOAD_PATH, env_name)
    return shared_packages(env_name; depot)
end

function sh_add(env_names; depot = first(DEPOT_PATH))
    pks = String[]
    for env_name in env_names
        append!(pks, sh_add(env_name; depot))
    end
    return pks |> unique! |> sort
end

function sh_add(envs::EnvSet)
    shared_envs = ["@$s" for s in envs.envs]
    sh_add(shared_envs)
end

sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) = sh_add(vcat(env_name, ARGS...); depot)

export sh_add

function list_env_pkgs(env_path) 
    project = TOML.parsefile(joinpath(env_path, "Project.toml"))
    return keys(project["deps"]) |> collect |> sort
end

function shared_packages(env_name; depot = first(DEPOT_PATH), skipfirstchar = true)
    p = env_path(env_name, depot; skipfirstchar)
    return list_env_pkgs(p)
end
export shared_packages

# list packages in the standard environment @stdlib
function stdlib_packages()
    pkg_dirlist = readdir(Sys.STDLIB) 
    pkgs = [s for s in pkg_dirlist if isdir(joinpath(Sys.STDLIB, s)) && !endswith(s, "_jll")]
    return pkgs
end
export stdlib_packages


"""
    check_packages(packages; depot = first(DEPOT_PATH)) -> NamedTuple

checks whether packages are available in the current environment, shared environments, or are installable.

Returns a NamedTuple with the following fields:

- `inpath_pkgs`: packages that are already present in some environment in `LOAD_PATH`
- `inshared_pkgs`: packages that are available in some shared environments
- `installable_pkgs`: available packages
- `unavailable_pkgs`: packages that are not available from any registry
- `shared_pkgs`: Dictionary of packages in shared environments
- `current_pr`: information about the current environment as `@NamedTuple{name::String, shared::Bool}`
"""
function check_packages(packages; depot = first(DEPOT_PATH)) # packages::AbstractVector{<:AbstractString}
    shared_pkgs = list_shared_packages(; depot)
    (; curr_pkgs, curr_pr_name, is_shared) = current_env()

    inpath_pkgs = String[]
    inshared_pkgs = String[]
    installable_pkgs = String[]
    unavailable_pkgs = String[]

    for pk in packages
        if (pk in curr_pkgs) || (pk in curr_pkgs)
            push!(inpath_pkgs, pk)
        else
            if pk in keys(shared_pkgs)
                if shared_pkgs[pk].in_path 
                    push!(inpath_pkgs, pk)
                else
                    push!(inshared_pkgs, pk)
                end
            elseif is_in_registries(pk)
                push!(installable_pkgs, pk)
            else
                push!(unavailable_pkgs, pk)
            end
        end
    end
    return (; inpath_pkgs, inshared_pkgs, installable_pkgs, unavailable_pkgs, shared_pkgs, current_pr = (;name=curr_pr_name, shared=is_shared))
end

check_packages(package::AbstractString; depot = first(DEPOT_PATH)) = check_packages([package]; depot) 

export check_packages

function current_env(; depot = first(DEPOT_PATH))
    pr = Base.active_project()
    pkgs = keys(TOML.parsefile(pr)["deps"])
    d = dirname(pr) |> basename
    (base_name, extension) = splitext(d)

    if (extension |> lowercase) == ".jl" 
        curr_pr_name = base_name
    else
        curr_pr_name = d
    end

    is_shared = curr_pr_name in list_shared_environments(; depot).shared_env_names

    return (; curr_pkgs=pkgs, curr_pr_name, is_shared)
end
export current_env

function is_in_registry(pkname, reg=nothing)
    isnothing(reg) && (reg = Pkg.Registry.reachable_registries()[1])
    pkgs = reg.pkgs
    for (_, pkg) in pkgs
        pkg.name == pkname && return true
    end
    return false
end
export is_in_registry

function is_in_registries(pkg_name)
    registries = Pkg.Registry.reachable_registries() 
    for reg in registries
        if is_in_registry(pkg_name, reg)
            return true
        end
    end
    return false
end
export is_in_registries

function make_importable(packages)
    (; inshared_pkgs, installable_pkgs, unavailable_pkgs, shared_pkgs, current_pr) = check_packages(packages)
    isempty(unavailable_pkgs) || error("The following packages are not available from any registry: $unavailable_pkgs")

    if isempty(installable_pkgs) 
        prompt2install(installable_pkgs, current_pr)
        (; inshared_pkgs, installable_pkgs, unavailable_pkgs, current_pr) = check_packages(packages)
        isempty(unavailable_pkgs) || error("The following packages are not available from any registry: $unavailable_pkgs")
        isempty(installable_pkgs) || error("The following packages should have been installed by now: $installable_pkgs")
    end

    if ! isempty(inshared_pkgs) 
        pkinfos = [shared_pkgs[p] for p in inshared_pkgs]
        envs2add = optim_set(pkinfos)
        sh_add(envs2add)
    end

    return nothing
end
export make_importable

function prompt2install(packages::AbstractVector{<:AbstractString}, current_pr)
    for p in packages
        prompt2install(p, current_pr)
    end
    return nothing
end

function prompt2install(package::AbstractString, current_pr)
    @show package

end