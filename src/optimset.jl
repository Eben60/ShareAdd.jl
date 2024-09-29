reducesets(envs) = reduce(union, Set(env.pkgs for env in envs))
export reducesets

reducenames(envs) = Set(env.name for env in envs)
export reducenames

# this method will be probably unused
function extraneous_pkgs(former_extra_pks, env::EnvInfo, required_pkgs)
    extraneous_pks = setdiff(env.pkgs, required_pkgs)
    newset = union(former_extra_pks, extraneous_pks)
    newlng = length(newset)
    return (; newset, newlng)
end
export extraneous_pkgs

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
    optimset.extra_lng = env_set.extra_lng
    optimset.no_of_sets = env_set.no_of_sets
    return optimset
end

function check_and_push!(optimset::OptimSet, env_set::EnvSet)
    if env_set.extra_lng > optimset.extra_lng
        return optimset
    elseif env_set.extra_lng < optimset.extra_lng 
        return replace!(optimset, env_set)
    elseif env_set.no_of_sets < optimset.no_of_sets
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
    return OptimSet(envset, envset.extra_lng, envset.no_of_sets)
end

function optim_set(pkgs::AbstractArray{PackageInfo})
    optimset = init_optimset(pkgs)

    env_sets = Tuple([p.envs for p in pkgs])
    required_pkgs = [p.name for p in pkgs]
    # return env_sets

    for env_combination in Iterators.product(env_sets...)
        # return env_combination 
        envset = Set([env_set(collect(env_combination), required_pkgs)])
        check_and_push!(optimset, envset)        
    end
    return optimset
end
export optim_set

# function 