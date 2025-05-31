"""
    sh_add(env_name::AbstractString; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH)) -> Vector{String}
    sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) -> Vector{String}

Adds shared environment(s) to `LOAD_PATH`, making the corresponding packages all available in the current session.

Returns the list of all packages in the added environments as a `Vector{String}`.

# Examples
```julia-repl
julia> using ShareAdd: sh_add
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

This function is public, not exported.
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


"""
    make_importable(pkg::AbstractString)
    make_importable(pkgs::AbstractVector{<:AbstractString})
    make_importable(pkg1, pkg2, ...)
    make_importable(::Nothing) => :success

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
julia> using Foo: bazaar as baz  # @usingany Foo: bazaar as baz is not a supported syntax
```

This function is public, not exported.
"""
function make_importable(packages)

    package_loaded(packages) && return :success

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

make_importable(::Nothing) = :success

function install_shared(p2is::AbstractVector{<:NamedTuple}, current_pr::EnvInfo)
    d = combine4envs(p2is)
    for (env, pkgs) in d
        install_shared(env, pkgs)
    end
    Pkg.activate(current_pr.path)
    return nothing
end

function install_shared(env, pkgs::Vector{String})
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

    Pkg.add(pkgs)

    return nothing
end

function combine4envs(p2is)
    d = Dict{Any, Vector{String}}()
    for p in p2is
        env = p.env
        pkg = p.pkg
        if haskey(d, env)
            push!(d[env], pkg)
        else
            d[env] = [pkg]
        end
    end
    return d
end

function env_prefix(env)
    startswith(env.name, "@") && return ""
    (env.shared && ! env.standard_env) ? "@" : ""
end

function env_suffix(env)
    #TODO current, active, temporary, and all corner cases
    env.standard_env && return " (standard Jula environment)"
    env.active_project && return " (current active project)"
    return ""
end

env_info2show(env::EnvInfo) = env_prefix(env) * env.name * env_suffix(env)
env_info2show(env::AbstractString) = env

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
function prompt2install(packages::AbstractVector{<:AbstractString}; env2exclude = [])
    to_install = NamedTuple[]
    newenvs = String[]
    for p in packages
        e = prompt2install(p, newenvs; env2exclude)
        isnothing(e) && return nothing
        push!(to_install, (; pkg=p, env=e))
        (e isa AbstractString) && !(e in newenvs) && push!(newenvs, e)
    end
    return to_install
end

function prompt2install(new_package::AbstractString, newenvs = String[]; envs = shared_environments_envinfos().shared_envs, env2exclude = [])
    (; options, envs) = prompt2install_preproc(new_package, newenvs, envs, env2exclude)
    menu = RadioMenu(options)

    @info "Use the arrow keys to move the cursor. Press Enter to select."
    println("\n" * "Please select a shared environment to install package $new_package" * "\n")

    menu_idx = request(menu)

    if (menu_idx == length(options)) || menu_idx <= 0
        @info "Quiting. No action taken."
        return nothing
    elseif menu_idx == 1
        p = prompt4newenv(new_package)
        # @show p
        return p
    else
        e = envs[menu_idx-1]
        # @show e
        return e

        # e isa EnvInfo && return e
        # return "@" * e.name
    end
end

prompt2install_preproc(new_package, newenvs, envs, env2exclude) = prompt2install_preproc(new_package, newenvs, envs, [env2exclude])

function prompt2install_preproc(new_package, newenvs, envs, env2exclude::AbstractVector)
    for env in env2exclude
        if hasproperty(env, :name)
            ename = env.name
        elseif startswith(env, "@")
            ename = env[2:end]
        else
            ename = env
        end
        delete!(envs, ename)
    end

    envs = envs |> values |> collect
    envs = convert(Array{Any}, envs)

    # isempty(newenvs) || (newenvs = [(;standard_env=false, active_project=false, shared=true, name=lstrip(e, '@')) for e in newenvs]) # faking env
    append!(envs, newenvs)
    sort!(envs, by=sortinghelp)

    currproj = current_env()
    currproj.shared || push!(envs, currproj)

    options = [env_info2show(env) for env in envs]
    pushfirst!(options, "A new shared environment (you will be prompted for the name)")
    push!(options, "Quit. Do Nothing.")
    return (; options, envs)
end

function sortinghelp(x)
    x isa EnvInfo && return (x.standard_env, x.name |> lowercase)
    startswith(x, "@") && return (false, x[2:end] |> lowercase)
    error("If $x is a shared env name, it must start with @")
end

function nothingtodo(ar)
    if isempty(ar)
        @info "Nothing to do"
        return true
    else
        return false
    end
end

function tidyup(nm::AbstractString = main_env_name(true))
    return nm |> getenvinfo |> tidyup
end

function tidyup(env::EnvInfo)
    if env.shared
        essential_pkgs = Set(["Revise", "ShareAdd", "OhMyREPL", "BasicAutoloads"])
        other_pkgs = setdiff(env.pkgs, essential_pkgs) |> collect |> sort!
    else
        other_pkgs = env.pkgs
    end
    nothingtodo(other_pkgs) && return nothing

    @info "Use the arrow keys to move the cursor. Press Enter to select."
    println("\n" * "Please select any packages you would like to KEEP in the environment @$(env.name)." * "\n" *
        "All other packages will be moved into other shared environment(s) in the following dialogs." * "\n")

    menu = MultiSelectMenu(other_pkgs)
    rqm = request(menu)
    menu_idx = rqm |> collect |> sort!
    # @show menu_idx

    keeped_pkgs = other_pkgs[menu_idx]
    moved_pkgs = setdiff(other_pkgs, keeped_pkgs)
    nothingtodo(moved_pkgs) && return nothing

    p = prompt2install(moved_pkgs; env2exclude=env)
    c = combine4envs(p)

end

function show_2be_installed(c)
    ks = keys(c) |> collect
    sort!(ks, by=sortinghelp)
    d = Dict{Any, String}()
    for k in ks
        if k isa AbstractString
            s = k * " (new env)"
        elseif k.standard_env
            s = k.name * " (default env)"
        else
            s = "@" * k.name
        end
        d[k] = s
    end
    longest = d |> values .|> length |> maximum
    return [rpad(d[k], longest) * " => " * string(c[k]) for k in ks]
end