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

function env_set(envs::AbstractArray{EnvInfo}, required_pkgs)
    pkgs = reducesets(envs)
    extraneous_pks = setdiff(pkgs, required_pkgs)
    lng = length(extraneous_pks)
    nms = reducenames(envs)
    return EnvSet(nms, extraneous_pks, lng)
end
export env_set

function check_and_push!(optimset::OptimSet, env_set::EnvSet)
    if env_set.extra_lng > optimset.extra_lng
        return optimset
    elseif env_set.extra_lng < optimset.extra_lng 
        empty!(optimset.env_sets)
        push!(optimset.env_sets, env_set)
        optimset.extra_lng = env_set.extra_lng
        return optimset
    else
        push!(optimset.env_sets, env_set)
    end
end

check_and_push!(optimset::OptimSet, env_sets::T) where T <: Union{AbstractArray{EnvSet}, AbstractSet{EnvSet}} = check_and_push!.(Ref(optimset), env_sets)


function optim_set(pkgs::AbstractArray{PackageInfo})
    optimset = OptimSet()
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