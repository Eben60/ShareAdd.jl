using Random
using StatsBase

function rnd_p_sample(pks, max_size; musthave=nothing)
    sz = rand(1:max_size)
    s = sample(pks, sz, replace=false)
    sort!(s)

    if !isnothing(musthave)
        musthave in s && return s
        i = rand(1:sz)
        s[i] = musthave
        sort!(s)
        return s
    end
    return s
end
export rnd_p_sample

rnd_env(pks, max_size, name=""; musthave=nothing) = 
    EnvInfo(; name, pkgs=rnd_p_sample(pks, max_size; musthave))
export rnd_env

function rnd_pk_envs(pk, pks, max_size, max_envs) 
    envs = EnvInfo[]
    for i in 1:rand(1:max_envs)
        push!(envs, rnd_env(pks, max_size; musthave=pk))
    end
    unique!(x -> x.pkgs, envs)
    sort!(envs; by=x -> length(x.pkgs), rev=true)
    return envs
end
export rnd_pk_envs

function rnd_pkgs_envs(; no_pks=6, pks=nothing, total_pks=10, max_size=8, max_envs=5)
    isnothing(pks) && (pks = ["P$i" for i in 1:total_pks])

    pckg_names = sample(pks, no_pks, replace=false) |> sort!
    return [PackageInfo(p, rnd_pk_envs(p, pks, max_size, max_envs), false) for p in pckg_names]
end
export rnd_pkgs_envs

