
is_minor_version(v1::VersionNumber, v2::VersionNumber) = 
    v1.major == v2.major && v1.minor == v2.minor

"""
    shared_environments_envinfos(; depot = first(DEPOT_PATH)) -> 
        (; shared_envs::Vector{EnvInfo},
        envs_folder_path::String, 
        shared_env_names::Vector{String})

"""
function shared_environments_envinfos(; depot = first(DEPOT_PATH))
    envs_folder_path = joinpath(depot, "environments")
    j_env = nothing
    shared_envs = EnvInfo[]

    if !isdir(envs_folder_path)
        return (; shared_envs=String[], envs_folder_path=nothing, shared_env_names=String[])
    else
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
            push!(shared_envs, envinfo)
        end

        !isnothing(j_env) && push!(shared_envs, j_env)
        shared_env_names = [s.name for s in shared_envs]
        return (; shared_envs, envs_folder_path, shared_env_names)
    end
end

"""
    list_shared_envs() -> Vector{String}
    list_shared_envs(pkg_name) -> Vector{String}

Returns the names of all shared environments (if called without an argument), or 
the environment(s) containing the package `pkg_name`.
"""
list_shared_envs() = shared_environments_envinfos().shared_env_names

function list_shared_envs(pkg_name)
    pkgs = list_shared_packages()
    haskey(pkgs, pkg_name) || error("Package $pkg_name not found")
    return [e.name for e in list_shared_packages()[pkg_name].envs]
end

"""
    list_shared_packages(;depot = first(DEPOT_PATH)) -> Dict{String, PackageInfo}
"""
function list_shared_packages(; depot = first(DEPOT_PATH))
    (; shared_envs, ) = shared_environments_envinfos(; depot)
    packages = Dict{String, PackageInfo}()
    for env in shared_envs
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

    # add packages in @stdlib
    std_pcks = stdlib_packages()
    for pk in std_pcks
        packages[pk] = PackageInfo(pk, EnvInfo[], true, true)
    end
    return packages
end

"""
    list_shared_pkgs(; all=false) -> Vector{String}
    list_shared_pkgs(env_name) -> Vector{String}

Returns the names of packages in all shared environments, or in given environment. 
If `all=true`, also includes packages in @stdlib.

# Examples
```julia-repl
julia> list_shared_pkgs()
5-element Vector{String}:
"foo"
"bar"
"baz"
"qux"
"quux"

julia> list_shared_pkgs("@Qu")
2-element Vector{String}:
"qux"
"quux"

```
"""
function list_shared_pkgs(; all=false)
    packages = list_shared_packages()
    all && return collect(keys(packages)) |> sort
    return collect(keys(filter(p -> !p.second.in_stdlib, packages))) |> sort
end

function list_shared_pkgs(env_name)
    is_shared_environment(env_name) || error("Environment $env_name is not a shared environment")
    return shared_packages(env_name)
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

"""
    sh_add(env_name::AbstractString; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) -> Vector{String}

Adds shared environment(s) to `LOAD_PATH`, making the corresponding packages all available in the current session.

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


function list_env_pkgs(env_path) 
    fl = joinpath(env_path, "Project.toml")
    isfile(fl) || return String[]
    project = TOML.parsefile(joinpath(env_path, "Project.toml"))
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
"""
function current_env(; depot = first(DEPOT_PATH))
    shared_envs = shared_environments_envinfos(; depot)

    shared_env_paths = [env.path for env in shared_envs.shared_envs]


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
        for e in shared_envs.shared_envs
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

"""
    make_importable(pkg::AbstractString)
    make_importable(pkgs::AbstractVector{<:AbstractString})
    make_importable(pkg1, pkg2, ...)

Checks  packages (by name only, UUIDs not supported!), prompts to install packages which are not in any shared environment, 
and adds relevant shared environments to `LOAD_PATH`.

`make_importable` is used internally by `@usingany`, but it can be used separately e.g. 
if you e.g. want to import a package via `import` statement instead of `using`.

Returns `:success` if the operation was successful, and `nothing` if the user selected "Quit. Do Nothing." on any of the prompts.

Throws an error on unavailable packages.

# Examples
```julia-repl
julia> using ShareAdd
julia> make_importable("Foo")
:success
julia> import Foo 

julia> using ShareAdd
julia> make_importable("Foo")
:success
julia> using Foo: @bar # @usingany Foo: @bar is not a supported syntax
```
"""
function make_importable(packages)
    (; inshared_pkgs, installable_pkgs, unavailable_pkgs, shared_pkgs, current_pr) = check_packages(packages)
    isempty(unavailable_pkgs) || error("The following packages are not available from any registry: $unavailable_pkgs")

    if !isempty(installable_pkgs) 
        p2i = prompt2install(installable_pkgs, )

        isnothing(p2i) && return nothing

        install_shared(p2i, current_pr) 

        (; inshared_pkgs, installable_pkgs, unavailable_pkgs, shared_pkgs, current_pr) = check_packages(packages)
        isempty(unavailable_pkgs) || error("The following packages are not available from any registry: $unavailable_pkgs")
        isempty(installable_pkgs) || error("The following packages should have been installed by now: $installable_pkgs")
    end

    if ! isempty(inshared_pkgs) 
        pkinfos = [shared_pkgs[p] for p in inshared_pkgs]
        envs2add = optim_set(pkinfos)
        sh_add(envs2add)
    end

    return :success
end

function make_importable(arg::AbstractString, args...)
    [arg, args...]
    return make_importable([arg, args...])
end

function install_shared(p2is::AbstractVector, current_pr)  
    for p2i in p2is
        install_shared(p2i)
    end
    Pkg.activate(current_pr.path)
    return nothing
end

function install_shared(p2i::NamedTuple)
    p = p2i.pkg
    env = p2i.env

    if env isa EnvInfo
        if env.standard_env
            env2activate = ""
        elseif env.shared
            env2activate = "@" * env.name
        else
            env2activate = env.path
        end
    else
        env2activate = env
    end

    if isempty(env2activate) 
        Pkg.activate()
    else
        if startswith(env2activate, "@")
            shared = true
            env2activate = env2activate[2:end]
        else
            shared = false
        end
        Pkg.activate(env2activate; shared)
    end

    Pkg.add(p)

    return nothing
end

env_prefix(env) = (env.shared && ! env.standard_env) ? "@" : ""

function env_suffix(env)
    #TODO current, active, temporary, and all corner cases
    env.standard_env && return " (standard Jula environment)"
    env.active_project && return " (current active project)"
    return ""
end

env_info2show(env) = env_prefix(env) * env.name * env_suffix(env)

function prompt4newenv(new_package)
    print("Please enter a name for the new shared environment, \nor press Enter to accept @$new_package: ")
    answer = readline(stdin)
    answer = strip(answer)
    isempty(answer) && (answer = "@$new_package")
    startswith(answer, "@") || (answer = "@" * answer)
    return answer
end

"""
    prompt2install(packages::AbstractVector{<:AbstractString})
    prompt2install(package::AbstractString)

Prompt user to select a shared environment to install a package or packages.

For a single package, if the user selects an environment, the package will be installed there. 
If the user selects "A new shared environment (you will be prompted for the name)", the user will be prompted to enter a name for a new environment. 

For multiple packages, the function will be called on each package and the user will be prompted for each package.

The function will return a vector of NamedTuples, each with field `pkg` and `env`, 
where `pkg` is the name of the package and `env` is the environment where it should be installed.

The function will return `nothing` if the user selects "Quit. Do Nothing." on any of the prompts.
"""
function prompt2install(packages::AbstractVector{<:AbstractString})
    to_install = []
    for p in packages
        e = prompt2install(p)
        isnothing(e) && return nothing
        push!(to_install, (; pkg=p, env=e))
    end
    return to_install
end

function prompt2install(new_package::AbstractString; envs = shared_environments_envinfos().shared_envs)
    currproj = current_env()
    currproj.shared || push!(envs, currproj)

    options = [env_info2show(env) for env in envs]
    push!(options, "A new shared environment (you will be prompted for the name)")
    push!(options, "Quit. Do Nothing.")
    menu = RadioMenu(options)

    println("Use the arrow keys to move the cursor. Press Enter to select.")
    println("Please select a shared environment to install package $new_package")

    menu_idx = request(menu)

    if (menu_idx == length(options)) || menu_idx <= 0
        @info "Quiting. No action taken."
        return nothing
    elseif menu_idx == length(options) - 1
        return prompt4newenv(new_package)
    else
        return envs[menu_idx]
    end
end


"""
    reset_loadpath!()

Resets the LOAD_PATH to the default values: removes any manually added paths, and resets the load path to the standard
values of ["@", "@v#.#", "@stdlib"]. 
"""
function reset_loadpath!()
    default_paths = ["@", "@v#.#", "@stdlib"]
    empty!(LOAD_PATH)
    append!(LOAD_PATH, default_paths)
    return nothing  
end

"""
    delete_shared_env(env::Union{AbstractString, EnvInfo})

Deletes the shared environment `env` by erasing it's directory.

Returns `nothing`.
"""
delete_shared_env(e::EnvInfo) = (rm(e.path; recursive=true); return nothing)

function delete_shared_env(s::AbstractString)
    startswith(s, "@") || error("Name of shared environment must start with @")
    s = s[2:end]

    for env in shared_environments_envinfos().shared_envs
        env.name == s && return delete_shared_env(env)
    end

    error("Shared environment $s not found")
end

"""
    delete_shared_pkg(pkg::AbstractString)

Deletes the package `pkg` from it's shared environment. Deletes this environment if it was the only package there.
If the package is present in multiple environments, it will not be deleted and an error will be thrown, suggesting you do it manually.

Returns `nothing`.
"""
function delete_shared_pkg(s::AbstractString)
    curr_env = current_env()
    pkinfos = list_shared_packages()
    haskey(pkinfos, s) || error("Package $s not found")

    p = pkinfos[s]

    p.in_path && error("Package $s is in path. Remove it's environment form the path first.")
    
    length(p.envs) > 1 && error("Package $s is present in multiple environments $([env.name for env in p.envs]). Remove it manually.")
    e = p.envs[1]

    onlyone = length(e.pkgs) == 1

    Pkg.activate(e.path)
    Pkg.rm(s)
    Pkg.activate(curr_env.path)
    onlyone && delete_shared_env(e)

    return nothing
end

function getenvinfo(nm::AbstractString)
    isenv = startswith(nm, "@")
    isenv || error("Name of shared environment must start with @")
    nm = nm[2:end]
    (; shared_envs, shared_env_names) = shared_environments_envinfos()
    nm in shared_env_names || error("Shared environment $nm not found")
    env = shared_envs[findfirst(x -> x.name == nm, shared_envs)]
    return env
end
