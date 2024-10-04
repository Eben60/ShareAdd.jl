reducesets(envs) = reduce(union, Set(env.pkgs for env in envs))
export reducesets

reducenames(envs) = Set(env.name for env in envs)
export reducenames

# # this method will be probably unused
# function extraneous_pkgs(former_extra_pks, env::EnvInfo, required_pkgs)
#     extraneous_pks = setdiff(env.pkgs, required_pkgs)
#     newset = union(former_extra_pks, extraneous_pks)
#     newlng = length(newset)
#     return (; newset, newlng)
# end
# export extraneous_pkgs

function env_set(envs::T, required_pkgs) where T <: Union{AbstractArray{EnvInfo}, AbstractSet{EnvInfo}}
    pkgs = reducesets(envs)
    extraneous_pks = setdiff(pkgs, required_pkgs)
    lng = length(extraneous_pks)
    nms = reducenames(envs)
    no_of_sets = length(nms)
    return EnvSet(nms, extraneous_pks, lng, no_of_sets)
end
export env_set

function replace!(optimset::OptimSet, env_set::EnvSet)
    optimset.best_set = env_set
    # optimset.best_set.extra_lng = env_set.extra_lng
    # optimset.best_set.no_of_sets = env_set.no_of_sets
    return optimset
end

function check_and_push!(optimset::OptimSet, env_set::EnvSet)
    if env_set.extra_lng > optimset.best_set.extra_lng
        return optimset
    elseif env_set.extra_lng < optimset.best_set.extra_lng 
        return replace!(optimset, env_set)
    elseif env_set.no_of_sets < optimset.best_set.no_of_sets
        return replace!(optimset, env_set)
    else
        return optimset
    end
end

check_and_push!(optimset::OptimSet, env_sets::T) where T <: Union{AbstractArray{EnvSet}, AbstractSet{EnvSet}} = 
    check_and_push!.(Ref(optimset), env_sets)


function init_optimset(pkgs::AbstractArray{PackageInfo})
    required_pkgs = [p.name for p in pkgs]
    envs = Set(vcat((p.envs for p in pkgs)...))
    envset = env_set(envs, required_pkgs)
    return OptimSet(envset)
end


"""
    optim_set(pks::AbstractArray{<:AbstractString}, envs::AbstractVector{EnvInfo}) -> OptimSet
    optim_set(pkgs::AbstractArray{PackageInfo}) -> OptimSet

Find the optimum set of environments for the given list of packages. 
Optimal is a set of environments with the least number of extraneous packages. 
If two sets have the same number of extraneous packages, then the one with the least number of environments is chosen.

The function is internal.
"""
function optim_set(pkgs::AbstractArray{PackageInfo})
    optimset = init_optimset(pkgs)

    env_sets = Tuple([p.envs for p in pkgs])
    required_pkgs = [p.name for p in pkgs]
    # return env_sets

    for env_combination in Iterators.product(env_sets...)
        envset = Set(collect(env_combination)) 
        recurse_sets!(optimset, envset, required_pkgs)      
    end
    return optimset.best_set
end

optim_set(pks::AbstractArray{<:AbstractString}, envs::AbstractVector{EnvInfo}) = optim_set(make_pkginfos(pks, envs))

export optim_set

function sortpkgs!(pkgs::AbstractVector{PackageInfo})
    sort!(pkgs; by=x -> length(x.envs), rev=true)
end

function remove_redundant_envs!(pkgs::AbstractVector{PackageInfo})
    sortpkgs!(pkgs)
    l = length(pkgs)
    for i in 2:l
        for j in 1:(i-1)
            pkgs[i].envs = setdiff(pkgs[i].envs, pkgs[j].envs)
        end
    end
    sortpkgs!(pkgs)
    return pkgs
end
export remove_redundant_envs!

recurse_sets!(optimset::OptimSet, envinfos::Set{EnvInfo}, required_pkgs) = 
    recurse_sets!(optimset, collect(envinfos), required_pkgs) 

function recurse_sets!(optimset::OptimSet, envinfos::Vector{EnvInfo}, required_pkgs)
    redset = reducesets(envinfos)
    if !issubset(required_pkgs, redset)
        return nothing
    end
    
    if length(envinfos) >1
        for i in eachindex(envinfos)
            otherenvs = deleteat!(copy(envinfos), i)
            recurse_sets!(optimset, otherenvs, required_pkgs)
        end
    end

    envset = env_set(envinfos, required_pkgs)
    check_and_push!(optimset, envset)
    return nothing
end

make_pkginfos(pknames::AbstractVector{<:AbstractString}, envs::AbstractVector{EnvInfo}) = 
    [PackageInfo(pkname, filter(env -> pkname in env.pkgs, envs), false) for pkname in pknames]

export make_pkginfos