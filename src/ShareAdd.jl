module ShareAdd
using TOML

function list_shared_environments(depot = first(DEPOT_PATH))
    shared_environments = joinpath(depot, "environments")
    if !isdir(shared_environments)
        return String[]
    else
        sh_envs = readdir(shared_environments)
        return [s for s in sh_envs if isdir(joinpath(shared_environments, s))]
    end
end
export list_shared_environments

function env_path(env_name::AbstractString, depot = first(DEPOT_PATH))
    env_name = env_name[2:end]
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
 "CSV"
 "DataFrames"
 "Dates"

julia> sh_add(["@StatPackages", "@Makie"])
4-element Vector{String}:
 "CSV"
 "DataFrames"
 "Dates"
 "Makie"

julia> sh_add("@StatPackages", "@Makie")
4-element Vector{String}:
 "CSV"
 "DataFrames"
 "Dates"
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

function shared_packages(env_name; depot = first(DEPOT_PATH))
    p = env_path(env_name, depot)
    project = TOML.parsefile(joinpath(p, "Project.toml"))
    return keys(project["deps"]) |> collect |> sort
end

end # module ShAdd
