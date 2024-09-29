recurse_sets!(optimset::OptimSet, envinfos::Set{EnvInfo}, required_pkgs) = 
    recurse_sets!(optimset, collect(envinfos), required_pkgs) 

function recurse_sets!(optimset::OptimSet,  envsets::Set{EnvSet}, required_pkgs)
    

end

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


function optim_set2(pkgs::AbstractArray{PackageInfo})
    optimset = init_optimset(pkgs)

    required_pkgs = [p.name for p in pkgs]
    envs = Set(vcat((p.envs for p in pkgs)...))
    recurse_sets!(optimset, envs, required_pkgs)
    return optimset
end
export optim_set2