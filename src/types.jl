"""
    mutable struct EnvInfo

- `name::String` - name of the environment
- `path::String` - path of the environment's folder
- `pkgs::Vector{String}` - list of packages in the environment
- `in_path::Bool` - whether the environment is in `LOAD_PATH` 
"""
@kwdef mutable struct EnvInfo
    name::String = ""
    path::String = ""
    pkgs::Set{String} = Set{String}()
    in_path::Bool = false
    standard_env::Bool = false
    shared::Bool = true
    temporary::Bool = false
    active_project::Bool = false
end

EnvInfo(name, path, pkgs::AbstractVector{<:AbstractString}, in_path) = EnvInfo(; name, path, pkgs = Set(pkgs), in_path)
Base.:(==)(a::EnvInfo, b::EnvInfo) = a.name == b.name

mutable struct PackageInfo
    const name::String
    envs::Vector{EnvInfo}
    in_path::Bool
end

struct EnvSet
    envs::Set{String}
    extraneous_pks::Set{String}
    extra_lng::Int
    no_of_sets::Int
end

mutable struct OptimSet
    best_set::EnvSet
end