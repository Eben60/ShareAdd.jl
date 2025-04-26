"""
    info(nms::Union{Nothing, String, Vector{String}} = nothing; 
        by_env=true, listing=nothing, std_lib=false, upgradable=false, disp_rslt=true, ret_rslt=false)

Prints out and/or returns information about shared environments.

# Argument
- `nms`: Name(s) of package(s) or environment(s) to return the information on. Environment names must start with "@". Package and env names cannot be provided together in one array.

# Keyword arguments
- `by_env=true`: whether to print out results as a `Dict` of pairs like `@env => [pkg1, ...]`, or `pkg => [@env1, ...]`. Has no effect on returned (if any) results.
- `listing=nothing`: this kwarg can be `nothing`, `:envs`, or `:pkgs`. If one of these two `Symbol`s is provided, the result is printed as a vector of envs or pkgs, resp. In this case `by_env` is ignored. Has no effect on returned (if any) results
- `upgradable=false`: if true, all other kwargs will be ignored, and only upgradable packages with installed vs. most recent versions will be printed, ordered by environment. 
- `disp_rslt=true`: whether to print out results.
- `ret_rslt=false`: whether the function returns anything. If set to `true`, it returns a NamedTuple `(; env_dict, pkg_dict, envs, pkgs, absent)`, where the two first elements are  `Dict`s with keywords correspondingly by env or by pkg; `envs` and `pkgs` are vectors of  respective elements, and `absent` are those names provided through the `nms` argument, which  are not contained in the shared envs. Names of envs in the returned data are without leading "@".

This function is public, but **not exported**, as to avoid possible name conflicts. 

    # Examples
```julia-repl
julia> ShareAdd.info(["BenchmarkTools", "Chairmarks"])
The following packages are not in any shared env:
    ["Chairmarks"]

Found pkgs/envs:
  @BenchmarkTools
   => ["BenchmarkTools"]
  @Tools
   => ["BenchmarkTools"]

julia> ShareAdd.info(["DataFrames", "CSV"]; by_env=false)
  CSV
   => ["@DataFrames"]
  DataFrames
   => ["@DataFrames"]

julia> ShareAdd.info("StaticArrays"; upgradable=true)
  @StaticArrays
    StaticArrays: 1.9.8 --> 1.9.10   
```
"""
info(nm::AbstractString; kwargs...) = info([nm]; kwargs...)

function info(nms=nothing; by_env=true, listing=nothing, std_lib=false, upgradable=false, disp_rslt=true, ret_rslt=false)
    are_env_names = nothing
    if !isnothing(nms)
        all_same_art(nms) || error("List of names must be either all environments or all packages")
        are_env_names = startswith(nms[1], "@")
        sort!(nms)
    end    

    (; shared_envs) = shared_environments_envinfos(; std_lib = (std_lib && !upgradable))
    env_dict0 = Dict{String, Vector{String}}(k => (e.pkgs |> collect |> sort) for (k, e) in shared_envs)

    (; env_dict, pkg_dict, absent) = dict_for_names(env_dict0, nms, are_env_names)

    if upgradable
        print_absent(absent, are_env_names)
        if (!by_env || std_lib || !isnothing(listing) || !disp_rslt || ret_rslt)
            @warn "With `upgradable` kwarg, all other kwargs are ignored"
        end
        return display_upgradable(shared_envs, env_dict, pkg_dict)
    end

    d = by_env ? env_dict : pkg_dict

    disp_rslt && display_results(d, absent, are_env_names, by_env, listing)

    ret_rslt || return nothing
    
    envs = keys(env_dict) |> collect |> sort!
    pkgs = keys(pkg_dict) |> collect |> sort!
    return (; env_dict, pkg_dict, envs, pkgs, absent)
end

function display_results(d, absent, are_env_names, by_env, listing)
    if isnothing(are_env_names) || isempty(absent)
        print_dict(d; by_env, listing)
    else
        print_absent(absent, are_env_names)
        if !isempty(d)
            println()
            println("Found pkgs/envs:")
            print_dict(d; by_env, listing)
        end
    end
    return nothing
end

function print_absent(absent, are_env_names)
    isempty(absent) && return 
    if are_env_names 
        absent = ["@" * o for o in absent] |> sort!
        println("The following shared envs do not exist:")
    else
        println("The following packages are not in any shared env:")
    end
    println("    $absent")
    return nothing
end

function display_upgradable(shared_envs, env_dict, pkg_dict)
    upgradable_envs = []

    all_envs = env_dict |> keys
    all_pkgs = pkg_dict |> keys |> collect
    lastversions = latest_version(all_pkgs)
    
    for (nm, env) in shared_envs
        nm in all_envs || continue
        upgradable_pks = []
        pkgs = env.pkgs
        specific_pkgs = intersect(all_pkgs, pkgs)
        installed_v = pkg_version(env, specific_pkgs)
        for pkg in specific_pkgs
            if installed_v[pkg] < lastversions[pkg]
                push!(upgradable_pks, (; pkg, installed=installed_v[pkg], latest=lastversions[pkg]))
            end
        end
        if !isempty(upgradable_pks)
            sort!(upgradable_pks, by=x->x.pkg)
            push!(upgradable_envs, (; env=env.name, pkgs=upgradable_pks))
        end
    end

    if isempty(upgradable_envs)
        println("All packages are up to date")
    else
        sort!(upgradable_envs, by=x->x.env)
        print_upgradable(upgradable_envs)
    end
    return nothing
end

function print_upgradable(upgradable_envs)
    for e in upgradable_envs
        (; env, pkgs) = e
        println("  @$env")
        for p in pkgs
            println("    $(p.pkg): $(p.installed) --> $(p.latest)")
        end
    end
end

function all_same_art(nms)
    is_env = startswith.(nms, "@")
    return all(x -> x == is_env[1], is_env) 
end

function invert_dict(d) # TODO deal with orphan names
    prs = []
    for (k, vs) in d
        for v in vs
            push!(prs, v => k)
        end
    end
    sort!(prs; by = x -> (x.first, x.second))
    
    d_inv = Dict{String, Vector{String}}()
    for p in prs
        if haskey(d_inv, p.first)
            push!(d_inv[p.first], p.second)
        else
            d_inv[p.first] = [p.second]
        end
    end
    return d_inv

end

function dict_for_names(env_dict0, nms, are_env_names)
    if are_env_names == true
        nms = [nm[2:end] for nm in nms]
        (env_dict, absent) = dict_selection(env_dict0, nms)
        pkg_dict = env_dict |> invert_dict
    elseif are_env_names == false
        pkg_dict0 = env_dict0 |> invert_dict
        (pkg_dict, absent) = dict_selection(pkg_dict0, nms)
        env_dict = pkg_dict|> invert_dict
    else # are_env_names == nothing
        env_dict = env_dict0
        pkg_dict = env_dict |> invert_dict
        absent = String[]
    end
    return (;env_dict, pkg_dict, absent)
end

function dict_selection(d0, nms)
    d_fnd = Dict{String, Vector{String}}()
    absent = setdiff(nms, keys(d0))
    found = intersect(keys(d0), nms)
    for nm in found
        d_fnd[nm] = d0[nm]
    end
    return (; d_fnd, absent)
end

function print_dict(d; by_env=true, listing)
    if isnothing(listing)
        p = pairs(d) |> collect |> sort!
        for (k, v) in p 
            if by_env
                k1 = "@$k"
                v1 = v |> sort
            else
                k1 = k
                v1 = ["@$x" for x in v] |> sort
            end

            println("  $k1")
            println("   => $v1")
        end
    elseif listing == :envs # ignore by_env
        ks = keys(d) |> collect|> sort
        println("  $ks")
    elseif listing == :pkgs # ignore by_env
        pkgs = collect_pkgs(d)
        println("  $pkgs")
    else
        error("Listing=$(listing) not recognized. Options are nothing, :envs, :pkgs")
    end

    return nothing
end

function collect_pkgs(d)
    pkgs = String[]
    for v in values(d)
        pkgs = append!(pkgs, v)
    end
    return pkgs
end

function latest_version(pkg_name::AbstractString; registry=nothing)
    registry = get_in_mem_registry(; registry)
    ch1 = pkg_name[1] |> uppercase
    k = "$ch1/$pkg_name/Versions.toml"
    toml = registry[k]
    v = TOML.tryparse(toml) |> keys .|> VersionNumber |> maximum
end

function latest_version(pkgs::AbstractVector{<:AbstractString}; registry=nothing)
    registry = get_in_mem_registry(; registry)
    return Dict(pkg_name => latest_version(pkg_name; registry) for pkg_name in pkgs)
end

function get_in_mem_registry(; registry=nothing)
    isnothing(registry) || return registry
    return first(Pkg.Registry.reachable_registries()).in_memory_registry
end

function pkg_version(env::EnvInfo, pkgname::AbstractString; manifest = nothing)
    manifest = get_manifest(env; manifest)
    try
        return manifest["deps"][pkgname][1]["version"] |> VersionNumber
    catch
        println("Not found: version $pkgname in $(env.name)")
    end
end

function pkg_version(env::EnvInfo, pkgs::AbstractVector{<:AbstractString}; manifest = nothing)
    manifest = get_manifest(env; manifest)
    return Dict(pkg => pkg_version(env, pkg; manifest) for pkg in pkgs)
end

pkg_version(envname::AbstractString, pkgname::AbstractString; manifest = nothing) = pkg_version(EnvInfo(envname), pkgname; manifest)
pkg_version(envname::AbstractString, pkgs::AbstractVector{<:AbstractString}; manifest = nothing) = pkg_version(EnvInfo(envname), pkgs; manifest)
pkg_version(env::EnvInfo; manifest = nothing) = pkg_version(env, collect(env.pkgs); manifest)
pkg_version(envname::AbstractString; manifest = nothing) = pkg_version(EnvInfo(envname); manifest)

function get_manifest(env::EnvInfo; manifest = nothing)
    isnothing(manifest) || return manifest
    manifile = make_current_mnf(env)
    return TOML.parsefile(manifile)
end