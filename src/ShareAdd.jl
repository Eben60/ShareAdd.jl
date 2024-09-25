module ShareAdd
using TOML

is_minor_version(v1::VersionNumber, v2::VersionNumber) = 
    v1.major == v2.major && v1.minor == v2.minor

@kwdef struct EnvInfo
    name
    path
    in_path
end

function list_shared_environments(depot = first(DEPOT_PATH))
    env_path = joinpath(depot, "environments")
    j_env = nothing
    shared_envs = EnvInfo[]

    if !isdir(env_path)
        return String[]
    else
        env_dirlist = readdir(env_path)
        envs = [s for s in env_dirlist if isdir(joinpath(env_path, s))]
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
            envinfo = EnvInfo(; name = env, path = joinpath(env_path, env), in_path)
            push!(shared_envs, envinfo)
        end

        !isnothing(j_env) && push!(shared_envs, j_env)
        return (; shared_envs, env_path)
    end
end
export list_shared_environments

@kwdef mutable struct PackageInfo
    const name::String
    const envs::Vector{EnvInfo}
    in_path::Bool
end

function list_shared_packages(;depot = first(DEPOT_PATH))
    (; shared_envs, ) = list_shared_environments(depot)
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
    sh_add(env_name::AbstractString; depot = first(DEPOT_PATH))
    sh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH))
    sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH))

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

function sh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH))
    pks = String[]
    for env_name in env_names
        append!(pks, sh_add(env_name; depot))
    end
    return pks |> unique! |> sort
end

sh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) = sh_add(vcat(env_name, ARGS...); depot)

export sh_add

function shared_packages(env_name; depot = first(DEPOT_PATH), skipfirstchar = true)
    p = env_path(env_name, depot; skipfirstchar)
    project = TOML.parsefile(joinpath(p, "Project.toml"))
    return keys(project["deps"]) |> collect |> sort
end
export shared_packages

# list packages in the standard environment @stdlib
function stdlib_packages()
    pkg_dirlist = readdir(Sys.STDLIB) 
    pkgs = [s for s in pkg_dirlist if isdir(joinpath(Sys.STDLIB, s)) && !endswith(s, "_jll")]
    return pkgs
end
export stdlib_packages

end # module ShAdd