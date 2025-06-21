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

> **⚠️ Note for Julia v1.12 in VSCode**  
>
> `make_importable` may need to install new packages, with dialogs implemented via `REPL.TerminalMenus`, which appear to be broken with Julia **v1.12** in **VSCode**. A warning will be issued before a call to `REPL.TerminalMenus` dialog, giving the user the possibility to abort. See package docs for more info and workarounds.

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
        return p
    else
        e = envs[menu_idx-1]
        return e
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
    sort!(envs, by=sortinghelp1)

    currproj = current_env()
    currproj.shared || push!(envs, currproj)

    options = [env_info2show(env) for env in envs]
    pushfirst!(options, "A new shared environment (you will be prompted for the name)")
    push!(options, "Quit. Do Nothing.")
    return (; options, envs)
end

function sortinghelp1(x)
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

function tidyup_preproc(env::EnvInfo)
    if env.standard_env
        essential_pkgs = Set(["Revise", "ShareAdd", "OhMyREPL", "BasicAutoloads"])
        other_pkgs = setdiff(env.pkgs, essential_pkgs)
    else
        other_pkgs = env.pkgs
    end
    nothingtodo(other_pkgs) && return nothing

    other_pkgs = other_pkgs |> collect |> sort!
    other_envs = shared_environments_envinfos(; std_lib=true).shared_envs
    current_pr = current_env()

    delete!(other_envs, env.name)

    pkg_in_mult_envs = String[]
    envs = other_envs |> values |> collect
    for pk in other_pkgs
        any([pk in e.pkgs for e in envs]) && push!(pkg_in_mult_envs, pk)
    end
    return (; other_pkgs, current_pr, pkg_in_mult_envs)
end

function tidyup_sortout_pkgs(env, rqm, other_pkgs, pkg_in_mult_envs)
    menu_idx = rqm |> collect |> sort!
    pkgs2keep = other_pkgs[menu_idx]
    removed_pkgs = setdiff(other_pkgs, pkgs2keep)
    nothingtodo(removed_pkgs) && return nothing

    kept_pkgs = setdiff(env.pkgs, removed_pkgs) |> collect |> sort!
    moved_pkgs = setdiff(removed_pkgs, pkg_in_mult_envs)
    removed_pkgs_in_multienv = intersect(pkg_in_mult_envs, removed_pkgs)
    return (; removed_pkgs, kept_pkgs, moved_pkgs, removed_pkgs_in_multienv)
end

"""
    tidyup()
    tidyup(env::AbstractString)
    tidyup(env::EnvInfo)

`Tidyup` helps users to move packages out of a crowded shared environment. 
When called without arguments, it applies to the main shared environment. 
It opens a series of dialogs, prompting the user to select which packages to move out and where to move them.

> **⚠️ Note for Julia v1.12 in VSCode**  
>
> `tidyup` relies on dialogs implemented via `REPL.TerminalMenus`, which appear to be broken with Julia **v1.12** in **VSCode**. A warning will be issued before a call to `REPL.TerminalMenus` dialog, giving the user the possibility to abort. See package docs for more info and workarounds.
"""
function tidyup(nm::AbstractString = main_env_name(true))
    return nm |> getenvinfo |> tidyup
end

function tidyup(env::EnvInfo)
    tp = tidyup_preproc(env::EnvInfo)
    isnothing(tp) && return nothing
    (; other_pkgs, current_pr, pkg_in_mult_envs) = tp

    @info "Use the arrow keys to move the cursor. Press Enter to select."
    println("\n" * "Please select any packages you would like to KEEP in the environment @$(env.name)." * "\n" *
        "All other packages will be moved into other shared environment(s) in the following dialogs." * "\n")

    menu = AbortableMultiSelectMenu(other_pkgs)
    rqm = request(menu)
    if 0 in rqm
        println("Cancelled - exiting program.")
        return nothing
    end

    tsp = tidyup_sortout_pkgs(env, rqm, other_pkgs, pkg_in_mult_envs)
    isnothing(tsp) && return nothing
    (; removed_pkgs, kept_pkgs, moved_pkgs, removed_pkgs_in_multienv) = tsp

    @info "These packages will be removed from $(env.name): $(removed_pkgs)."
    if isempty(kept_pkgs)
        @info "As no packages are kept, the environment $(env.name) will be deleted."
    else
        @info "Following packages are staying in the environment $(env.name) : $(kept_pkgs)."
    end

    isempty(removed_pkgs_in_multienv) || 
        @info "Following packages will be removed from $(env.name), but they are still available from other shared environments: $(removed_pkgs_in_multienv)."

    if !isempty(moved_pkgs)
        @info "Following packages will be moved to other shared environments: $(moved_pkgs)."
        cont_prompt = "Continue? You will now be asked to select env for each package."
    else
        cont_prompt = "Continue?"
    end
    
    ask_yes_no(cont_prompt, "Yes, go on.", "No, cancelling now.") ||
        (@info "Cancelled - exiting program." ; return nothing)

    if !isempty(moved_pkgs)
        p = prompt2install(moved_pkgs; env2exclude=env)
        isnothing(p) && (@info "Cancelled - exiting program." ; return nothing)
        
        c = combine4envs(p)
        s2bi = show_2be_installed(c)
        println()
        @info "Following packages will be moved to those environments:"
        println()
        foreach(x -> println(x), s2bi)
        println()
        ask_yes_no("Continue?", "Yes, go on.", "No, cancelling now.") ||
            (@info "Cancelled - exiting program." ; return nothing)
    end

    isempty(removed_pkgs) || delete_shared_pkg(env => removed_pkgs; force=true)
    if !isempty(moved_pkgs) 
        install_shared(p, current_pr)
    else
        Pkg.activate(current_pr.path)
    end

end

function show_2be_installed(c)
    ks = keys(c) |> collect
    sort!(ks, by=sortinghelp2)
    env_d = Dict{Any, String}()
    for k in ks
        if k isa AbstractString
            s = k * " (new env)"
        else
            s = env_info2show(k)
        end
        env_d[k] = s
    end

    pkgs1_d = Dict([k => ("[" * join(c[k], ", ") * "]") for k in ks])
    longest = pkgs1_d |> values .|> string .|> length |> maximum
    pkgs2_d = Dict(k => rpad(v, longest) for (k, v) in pkgs1_d)

    return [(pkgs2_d[k] * " => " *  env_d[k]) for k in ks]
end

function sortinghelp2(x)
    x isa EnvInfo && return (true, x.active_project, x.standard_env, x.name |> lowercase)
    startswith(x, "@") && return (false, false, false, x[2:end] |> lowercase) # newly created envs go first
    error("If $x is a shared env name, it must start with @")
end