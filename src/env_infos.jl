is_minor_version(v1::VersionNumber, v2::VersionNumber) = 
    v1.major == v2.major && v1.minor == v2.minor


"""
    env_folders(; depot = first(DEPOT_PATH), create=false) -> 
        (; envs_folder, main_env, envs_exist)

Returns a named tuple containing the path to the main folder holding all share environments,
the path to the main shared environment, and a boolean indicating whether the main environment
folder exists.

If `create=true`, the main environment folder will be created if it does not exist.
"""
function env_folders(; depot = first(DEPOT_PATH), create=false)
    envs_folder = joinpath(depot, "environments")
    main_env = joinpath(envs_folder, main_env_name())
    envs_exist = isdir(main_env)
    if create && !envs_exist 
        mkpath(main_env)
        envs_exist = isdir(main_env)
    end
    return (; envs_folder, main_env, envs_exist)
end

function main_env_name(prefixed=false)
    prefx = prefixed ? "@" : ""
    return "$(prefx)v$(VERSION.major).$(VERSION.minor)"
end

"""
    shared_environments_envinfos(; std_lib=false, depot = first(DEPOT_PATH)) -> 
        (; shared_envs::Dict{name, EnvInfo},
        envs_folder_path::String, 
        shared_env_names::Vector{String})
"""
function shared_environments_envinfos(; std_lib=false, depot = first(DEPOT_PATH))
    envs_folder_path =  env_folders(; depot).envs_folder
    shared_envs = Dict{String, EnvInfo}()

    isdir(envs_folder_path) || error("Environment folder $envs_folder_path not found")  

    env_dirlist = readdir(envs_folder_path)
    envs = [s for s in env_dirlist if isdir(joinpath(envs_folder_path, s))]
    for env in envs
        standard_env = false
        in_path = ("@$(env)" in LOAD_PATH)
        v = tryparse(VersionNumber, env) 
        if !isnothing(v) 
            if is_minor_version(VERSION, v) 
                in_path = true
                standard_env = true
            else
                continue
            end
        end
        path = joinpath(envs_folder_path, env)
        pkgs = list_env_pkgs(path) |> Set
        envinfo = EnvInfo(; name = env, path, pkgs, in_path, standard_env, shared = true, temporary = false, active_project = false)
        shared_envs[envinfo.name] = envinfo
    end

    shared_env_names = shared_envs |> keys |> collect |> sort!

    if std_lib 
        stdl = stdlib_env()
        shared_envs[stdl.name] = stdl
        append!(shared_env_names, stdl.pkgs)
        sort!(shared_env_names)
    end

    return (; shared_envs, envs_folder_path, shared_env_names)
end

"""
    list_shared_envs() -> Vector{String}
    list_shared_envs(pkg_name) -> Vector{String}

Returns the names of all shared environments (if called without an argument), or 
the environment(s) containing the package `pkg_name`.
"""
list_shared_envs(; std_lib = false) = shared_environments_envinfos(;std_lib).shared_env_names

function list_shared_envs(pkg_name; std_lib = false)
    pkgs = list_shared_packages(; std_lib)
    haskey(pkgs, pkg_name) || return String[]
    return [e.name for e in list_shared_packages(;std_lib)[pkg_name].envs]
end

"""
    list_shared_packages(;depot = first(DEPOT_PATH)) -> Dict{String, PackageInfo}
"""
function list_shared_packages(; std_lib = false, depot = first(DEPOT_PATH))
    (; shared_envs, ) = shared_environments_envinfos(; depot)
    packages = Dict{String, PackageInfo}()
    for env in shared_envs |> values
        pks = shared_packages(env.name; depot, skipfirstchar = false)
        for pk in pks
            if !haskey(packages, pk)
                p = PackageInfo(pk, [env], env.in_path, false)
                # p.in_path && empty!(p.envs) # if it is already in path, it doesn't matter which env it is
                packages[pk] = p
            else
                push!(packages[pk].envs, env)
                packages[pk].in_path |= env.in_path
                # packages[pk].in_path && empty!(packages[pk].envs)
            end
        end
    end

    if std_lib
        std_env = stdlib_env()
        std_pcks = std_env.pkgs
        for pk in std_pcks
            if haskey(packages, pk)
                pkg = packages[pk]
                pkg.in_path = true
                pkg.in_stdlib = true
                push!(pkg.envs, std_env)
            else
                packages[pk] = PackageInfo(pk, [std_env], true, true)
            end
        end
    end
    
    return packages
end

"""
    env_path(env_name::AbstractString, depot = first(DEPOT_PATH); skipfirstchar = true) -> String

Returns the path of the environment with name `env_name`. 
If `skipfirstchar` is `true`, the first character of `env_name` is skipped, 
so that the name of a shared environment can be passed without the leading `@`.
"""
function env_path(env_name::AbstractString, depot = first(DEPOT_PATH); skipfirstchar = true)
    skipfirstchar && (env_name = env_name[2:end])
    return joinpath(depot, "environments", env_name) 
end

function is_shared_environment(env_name::AbstractString, depot = first(DEPOT_PATH)) 
    startswith(env_name, "@") || error("Environment name must start with @")
    return env_path(env_name, depot) |> isdir
end 

function list_env_pkgs(env_path) 
    fl = joinpath(env_path, "Project.toml")
    isfile(fl) || return String[]
    project = TOML.parsefile(joinpath(env_path, "Project.toml"))
    haskey(project, "deps") || return String[]
    return keys(project["deps"]) |> collect |> sort
end

function shared_packages(env_name; depot = first(DEPOT_PATH), skipfirstchar = true)
    p = env_path(env_name, depot; skipfirstchar)
    return list_env_pkgs(p)
end

# list packages in the standard environment @stdlib
function stdlib_packages()
    pkg_dirlist = readdir(Sys.STDLIB) 
    pkgs = [s for s in pkg_dirlist if isdir(joinpath(Sys.STDLIB, s)) && !endswith(s, "_jll")]
    return pkgs
end

function stdlib_env()
    pkgs = stdlib_packages() |> Set
    env = EnvInfo(; name = "stdlib", path = Sys.STDLIB, pkgs, in_path = true, standard_env = true, shared = true, temporary = false, active_project = false)
    return env
end

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
    shared_pkgs = list_shared_packages(; std_lib=true, depot)
    current_pr = current_env()

    inpath_pkgs = String[]
    inshared_pkgs = String[]
    installable_pkgs = String[]
    unavailable_pkgs = String[]

    for pk in packages
        if (pk in current_pr.pkgs)
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
    return (; inpath_pkgs, inshared_pkgs, installable_pkgs, unavailable_pkgs, shared_pkgs, current_pr)
end

check_packages(package::AbstractString; depot = first(DEPOT_PATH)) = check_packages([package]; depot) 

"""
    current_env(; depot = first(DEPOT_PATH)) -> EnvInfo

Returns information about the current active environment as an `EnvInfo` object.

This function is public, not exported.
"""
function current_env(; depot = first(DEPOT_PATH))
    (; shared_envs) = shared_environments_envinfos(; depot)

    shared_env_paths = [env.path for env in shared_envs |> values]


    pr = Base.active_project()
    pkgs = isfile(pr) ? keys(TOML.parsefile(pr)["deps"]) : Set(String[])
    curr_pr_path = dirname(pr)
    d = curr_pr_path |> basename
    (base_name, extension) = splitext(d)

    if (extension |> lowercase) == ".jl" 
        curr_pr_name = base_name
    else
        curr_pr_name = d
    end

    is_shared = curr_pr_path in shared_env_paths

    if is_shared
        for e in shared_envs |> values
            if e.path == curr_pr_path
                env = copy(e)
                env.active_project = true
                return env
            end
        end
    else
        return EnvInfo(; name=curr_pr_name, pkgs, path=curr_pr_path, in_path=true, shared=false, active_project=true)
    end
    error("This code section should never be executed")    
end

function is_in_registry(pkname, reg=nothing)
    isnothing(reg) && (reg = Pkg.Registry.reachable_registries()[1])
    pkgs = reg.pkgs
    for (_, pkg) in pkgs
        pkg.name == pkname && return true
    end
    return false
end

function is_in_registries(pkg_name)
    registries = Pkg.Registry.reachable_registries() 
    for reg in registries
        if is_in_registry(pkg_name, reg)
            return true
        end
    end
    return false
end

function package_loaded(p)
    p_sym = Symbol(p)
    return (isdefined(Main, p_sym) && getproperty(Main, p_sym) isa Module)
end

function package_loaded(ps::Vector)
    for p in ps
        package_loaded(p) || return false
    end
    return true
end

function getenvinfo(nm::AbstractString) # :: EnvInfo
    startswith(nm, "@") || error("Name of shared environment must start with @")
    nm = nm[2:end]
    return shared_environments_envinfos().shared_envs[nm]
end
