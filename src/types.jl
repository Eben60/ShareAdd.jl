"""
    mutable struct EnvInfo
    EnvInfo(name::AbstractString) -> EnvInfo

- `name::String` - name of the environment
- `path::String` - path of the environment's folder
- `pkgs::Set{String}` - list of packages in the environment
- `in_path::Bool` - whether the environment is in `LOAD_PATH` 
- `standard_env::Bool = false` - if the env is the standard one (which is in the `v1.11` folder for Julia v1.11)
- `shared::Bool = true` - if shared env
- `temporary::Bool = false` - if temporary env
- `active_project::Bool = false` - if active project

# Examples
```julia-repl
julia> ShareAdd.EnvInfo("@DocumenterTools")
ShareAdd.EnvInfo("DocumenterTools", "/Users/eben60/.julia/environments/DocumenterTools", Set(["DocumenterTools"]), false, false, true, false, false)
```

This type is public, not exported.
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
EnvInfo(name::AbstractString) = getenvinfo(name)
Base.hash(e::EnvInfo, h::UInt) = hash((e.name, e.path, e.pkgs, e.in_path, e.standard_env, e.shared, e.temporary, e.active_project), h)

Base.:(==)(a::EnvInfo, b::EnvInfo) = hash(a) == hash(b) && 
    (a.name, a.path, a.pkgs, a.in_path, a.standard_env, a.shared, a.temporary, a.active_project) ==
        (b.name, b.path, b.pkgs, b.in_path, b.standard_env, b.shared, b.temporary, b.active_project)
        
Base.:copy(e::EnvInfo) = EnvInfo(e.name, e.path, copy(e.pkgs), e.in_path, e.standard_env, e.shared, e.temporary, e.active_project)

"""
    mutable struct PackageInfo

- `name::String` - name of the package
- `envs::Vector{EnvInfo}` - list of environments in which the package is present
- `in_path::Bool` - whether any of the environments is in `LOAD_PATH`

This type is public, not exported.
"""
mutable struct PackageInfo
    const name::String
    envs::Vector{EnvInfo}
    in_path::Bool
    in_stdlib::Union{Bool, Missing}
    is_registered::Union{Bool, Missing}
end

PackageInfo(name, envs, in_path, in_stdlib) = PackageInfo(name, copy(envs), in_path, in_stdlib, is_registered(name))

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
