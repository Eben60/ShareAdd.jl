"""
    info(nms::Union{Nothing, String, Vector{String}} = nothing; 
        by_env::Bool=true, listing=nothing, std_lib::Bool=false, upgradable::Bool=false, version::Bool=false, disp_rslt::Bool=true, ret_rslt::Bool=false, boolean::Bool=false) -> Union{Nothing, Bool, Vector{Bool}, NamedTuple}

Prints out and/or returns information about shared environments.

# Arguments
- `nms::Union{Nothing, String, Vector{String}}=nothing`: Name(s) of package(s) or environment(s) to return the information on. Environment names must start with "@". Package and env names cannot be provided together in one array.

# Keyword Arguments
- `by_env::Bool=true`: whether to print out results as a `Dict` of pairs like `@env => [pkg1, ...]`, or `pkg => [@env1, ...]`. Has no effect on returned (if any) results.
- `listing::Union{Nothing, Symbol}=nothing`: this kwarg can be `nothing`, `:envs`, or `:pkgs`. If one of these two `Symbol`s is provided, the result is printed as a vector of envs or pkgs, resp. In this case `by_env` is ignored. Has no effect on returned (if any) results
- `std_lib::Bool=false`: if true, info on standard library also returned.
- `upgradable::Bool=false`: if true, all other kwargs will be ignored (unless `version=true`), and only upgradable packages with installed vs. most recent versions will be printed, ordered by environment.
- `version::Bool=false`: if true, displays the installed versions of the packages. It requires `by_env=true` and `listing=nothing`, and errors if conflicting values are passed.
- `disp_rslt::Bool=true`: whether to print out results.
- `ret_rslt::Bool=false`: whether the function returns anything.
- `boolean::Bool=false`: if `true`, ignores other kwargs (forces `std_lib=true` and `disp_rslt=false`), and returns a `Bool` or `Vector{Bool}` indicating whether the provided package(s) or environment(s) are available. Calling with `boolean=true` but without `nms` errors.

# Returns
- `Nothing`: Returned by default if `ret_rslt=false` and `boolean=false` (or if `upgradable=true` and `version=false` even if `ret_rslt=true`).
- `Union{Bool, Vector{Bool}}`: Returned if `boolean=true`. Indicates whether the provided package(s) or environment(s) are available.
- `NamedTuple`: Returned if `ret_rslt=true`. The structure depends on the provided keyword arguments:
  - Default: `(; env_dict, pkg_dict, envs, pkgs, absent)`
  - With `version=true`: `(; env_dict, pkg_dict, envs, pkgs, absent, installed_versions)`
  - With `version=true` and `upgradable=true`: `(; env_dict, pkg_dict, envs, pkgs, absent, installed_versions, latest_versions)`
  
  The structures of the elements in the `NamedTuple` are:
  - `env_dict::Dict{String, Vector{String}}`: mappings from env name (without "@") to packages.
  - `pkg_dict::Dict{String, Vector{String}}`: mappings from package to env names.
  - `envs::Vector{String}`, `pkgs::Vector{String}`: sorted vectors of environments and packages.
  - `absent::Vector{String}`: names provided through the `nms` argument which are not contained in the shared envs.
  - `installed_versions::Dict{String, Dict{String, VersionNumber}}`: mappings of `pkg => env => version`.
  - `latest_versions::Dict{String, VersionNumber}`: mappings of `pkg => latest registry version`.

This function is public, but **not exported**, as to avoid possible name conflicts. 

# Examples
```julia-repl
julia> info();
  @BenchmarkTools
   => ["BenchmarkTools"]
  @DataFrames
   => ["CSV", "DataFrames", "Missings", "StringEncodings"]
 ...
  @v1.12
   => ["BasicAutoloads", "Revise", "ShareAdd", "TerminalPager"]

julia> ShareAdd.info(["BenchmarkTools", "Chairmarks"]);
The following packages are not in any shared env:
    ["Chairmarks"]

Found pkgs/envs:
  @BenchmarkTools
   => ["BenchmarkTools"]
  @Tools
   => ["BenchmarkTools"]

julia> ShareAdd.info(["DataFrames", "CSV"]; by_env=false);
  CSV
   => ["@DataFrames"]
  DataFrames
   => ["@DataFrames"]

julia> ShareAdd.info("StaticArrays"; upgradable=true);
  @StaticArrays
    StaticArrays: 1.9.8 --> 1.9.10

julia> ShareAdd.info("StaticArrays"; version=true);
  @StaticArrays
    StaticArrays: 1.9.8

julia> typeof(ShareAdd.info("DataFrames"; boolean=true))
Bool
```
"""
function info(nm::AbstractString; kwargs...)
    res = info([nm]; kwargs...)
    if get(kwargs, :boolean, false)
        return res[1]
    end
    return res
end

function info(nms=nothing; by_env=true, listing=nothing, std_lib=false, upgradable=false, version=false, disp_rslt=true, ret_rslt=false, boolean=false)
    if boolean
        isnothing(nms) && error("Cannot use `boolean=true` without providing `nms`.")
        std_lib = true
        disp_rslt = false
        version = false
    elseif version
        if !by_env || !isnothing(listing)
            error("When `version=true` is used, `by_env` must be `true` and `listing` must be `nothing`.")
        end
    end

    are_env_names = nothing
    local orig_nms_stripped = nothing
    if !isnothing(nms)
        all_same_art(nms) || error("List of names must be either all environments or all packages")
        are_env_names = startswith(nms[1], "@")
        orig_nms_stripped = are_env_names ? [n[2:end] for n in nms] : copy(nms)
        sort!(nms)
    end    

    (; shared_envs) = shared_environments_envinfos(; std_lib = (std_lib && !upgradable))
    env_dict0 = Dict{String, Vector{String}}(k => (e.pkgs |> collect |> sort) for (k, e) in shared_envs)

    (; env_dict, pkg_dict, absent) = dict_for_names(env_dict0, nms, are_env_names)

    if boolean
        return Bool[!(n in absent) for n in orig_nms_stripped]
    end

    installed_versions = nothing
    latest_versions = nothing

    if version
        installed_versions = Dict{String, Dict{String, VersionNumber}}()
        all_pkgs = keys(pkg_dict) |> collect
        
        for (nm, env) in shared_envs
            haskey(env_dict, nm) || continue
            
            specific_pkgs = intersect(all_pkgs, env.pkgs)
            installed_v = pkg_version(env, specific_pkgs)
            for (pkg, v) in installed_v
                isnothing(v) && continue
                if !haskey(installed_versions, pkg)
                    installed_versions[pkg] = Dict{String, VersionNumber}()
                end
                installed_versions[pkg][nm] = v
            end
        end
        
        if upgradable
            registered_pkgs = filter(p -> is_registered(p), all_pkgs)
            unregistered_pkgs = setdiff(all_pkgs, registered_pkgs)
            if !isempty(unregistered_pkgs)
                sort!(unregistered_pkgs)
                @info "The following packages are not registered and cannot be checked for updates: $unregistered_pkgs"
            end
            latest_versions = latest_version(registered_pkgs)
        end
        
        disp_rslt && display_versions_and_upgradable(env_dict, installed_versions, latest_versions, absent, are_env_names)
    elseif upgradable
        print_absent(absent, are_env_names)
        if (!by_env || std_lib || !isnothing(listing) || !disp_rslt || ret_rslt)
            @warn "With `upgradable` kwarg, all other kwargs are ignored"
        end
        return display_upgradable(shared_envs, env_dict, pkg_dict)
    else
        d = by_env ? env_dict : pkg_dict
        disp_rslt && display_results(d, absent, are_env_names, by_env, listing)
    end

    ret_rslt || return nothing
    
    envs = keys(env_dict) |> collect |> sort!
    pkgs = keys(pkg_dict) |> collect |> sort!
    
    if version && upgradable
        return (; env_dict, pkg_dict, envs, pkgs, absent, installed_versions, latest_versions)
    elseif version
        return (; env_dict, pkg_dict, envs, pkgs, absent, installed_versions)
    else
        return (; env_dict, pkg_dict, envs, pkgs, absent)
    end
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

function display_versions_and_upgradable(env_dict, installed_versions, latest_versions, absent, are_env_names)
    print_absent(absent, are_env_names)
    if !isempty(env_dict)
        !isempty(absent) && println()
        println("Found pkgs/envs:")
        sorted_envs = keys(env_dict) |> collect |> sort!
        for env in sorted_envs
            println("  @$env")
            pkgs = env_dict[env] |> sort
            for pkg in pkgs
                v = get(get(installed_versions, pkg, Dict()), env, nothing)
                if !isnothing(v)
                    if !isnothing(latest_versions) && haskey(latest_versions, pkg) && v < latest_versions[pkg]
                        println("    $pkg: $v --> $(latest_versions[pkg])")
                    else
                        println("    $pkg: $v")
                    end
                else
                    println("    $pkg: not found in manifest")
                end
            end
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
    unregistered_pkgs = String[]

    all_envs = env_dict |> keys
    all_pkgs = pkg_dict |> keys |> collect

    registered_pkgs = filter(p -> is_registered(p), all_pkgs)
    append!(unregistered_pkgs, setdiff(all_pkgs, registered_pkgs))

    lastversions = latest_version(registered_pkgs)
    
    for (nm, env) in shared_envs
        nm in all_envs || continue
        upgradable_pks = []
        pkgs = env.pkgs
        specific_pkgs = intersect(registered_pkgs, pkgs)
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

    some_unregistered = !isempty(unregistered_pkgs)
    if some_unregistered
        sort!(unregistered_pkgs)
        @info "The following packages are not registered and cannot be checked for updates: $unregistered_pkgs"
    end

    if isempty(upgradable_envs)
        unreg_clause = some_unregistered ? "(registered)" : ""
        println("All $(unreg_clause) packages are up to date")
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

function latest_version(pkg_name::AbstractString)
    for reg in Pkg.Registry.reachable_registries()
        for (_, entry) in reg.pkgs
            if entry.name == pkg_name
                # Pkg.Registry.registry_info is not public API;
                # its signature changed from (entry,) in Julia ≤1.12 
                # to (registry, entry) in Julia 1.13+
                info = if applicable(Pkg.Registry.registry_info, reg, entry)
                    Pkg.Registry.registry_info(reg, entry)
                else
                    Pkg.Registry.registry_info(entry)
                end
                versions = keys(info.version_info)
                return isempty(versions) ? v"0.0.0" : maximum(versions)
            end
        end
    end
    return v"0.0.0"
end

function latest_version(pkgs::AbstractVector{<:AbstractString})
    return Dict(pkg_name => latest_version(pkg_name) for pkg_name in pkgs)
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