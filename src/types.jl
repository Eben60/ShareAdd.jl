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
Base.:copy(e::EnvInfo) = EnvInfo(e.name, e.path, copy(e.pkgs), e.in_path, e.standard_env, e.shared, e.temporary, e.active_project)

"""
    mutable struct PackageInfo

- `name::String` - name of the package
- `envs::Vector{EnvInfo}` - list of environments in which the package is present
- `in_path::Bool` - whether any of the environments is in `LOAD_PATH`
"""
mutable struct PackageInfo
    const name::String
    envs::Vector{EnvInfo}
    in_path::Bool
    in_stdlib::Union{Bool, Missing}
end

"""
    struct EnvSet

- `envs::Set{String}` - set of environment names
- `extraneous_pks::Set{String}` - (internally used, see [`optim_set`](@ref) function for details)
- `extra_lng::Int` - as above
- `no_of_sets::Int` - as above
"""
struct EnvSet
    envs::Set{String}
    extraneous_pks::Set{String}
    extra_lng::Int
    no_of_sets::Int
end

"""
    mutable struct OptimSet

- `best_set::EnvSet` - the best set of environments currently found - see [`optim_set`](@ref) function for details.
"""
mutable struct OptimSet
    best_set::EnvSet
end
