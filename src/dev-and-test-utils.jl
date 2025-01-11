# this file is not included in ShareAdd package

using ShareAdd
using ShareAdd: PackageInfo, EnvInfo, OptimSet, EnvSet

using Random
sh_add("@StatsBase")
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

make_pknames(total_pks=9) = ["P$i" for i in 1:total_pks]

rnd_env(;pks=make_pknames(), max_size=8, name="", musthave=nothing) = 
    EnvInfo(; name, pkgs=rnd_p_sample(pks, max_size; musthave))
export rnd_env

function rnd_pk_envs(pk, pks, max_size, max_envs) 
    envs = EnvInfo[]
    for i in 1:rand(1:max_envs)
        push!(envs, rnd_env(; pks, max_size, musthave=pk))
    end
    unique!(x -> x.pkgs, envs)
    sort!(envs; by=x -> length(x.pkgs), rev=true)
    return envs
end
export rnd_pk_envs

function rnd_pkgs_envs(; no_pks=6, total_pks=10, pks=make_pknames(total_pks), max_size=8, max_envs=5)
    pckg_names = sample(pks, no_pks, replace=false) |> sort!
    return [PackageInfo(p, rnd_pk_envs(p, pks, max_size, max_envs), false) for p in pckg_names]
end
export rnd_pkgs_envs

set2vec(s) = collect(Set(s)) |> sort!

function generate_envs(; total_pks=10, no_envs=10, uniquenames=true, shuffled=true)
    # create array of environments of size no_envs
    envs = EnvInfo[]
    sizehint!(envs, no_envs)
    pks = make_pknames(total_pks)

    for i in 1:no_envs
        nm = "env$i"
        push!(envs, rnd_env(; name=nm, pks, max_size=8, musthave=nothing))
    end

    if uniquenames
        sort!(envs; by=x -> set2vec(x.pkgs))
        for i in 2:lastindex(envs)
            envs[i].pkgs == envs[i-1].pkgs && (envs[i].name = envs[i-1].name)
        end      
    end

    shuffled && shuffle!(envs)
    return envs
end
export generate_envs

filter_envs(pk_name, envs) =filter(x -> pk_name in x.pkgs, envs)
export filter_envs

function make_pkg(pk_name, envs, max_envs=5)
    fenvs = filter_envs(pk_name, envs)
    sz = rand(1:max_envs)
    s = sample(fenvs, sz, replace=false)
    return PackageInfo(pk_name, s, false)
end
export make_pkg

function make_pkgs(envs; max_envs=5, pkgs_no=5, total_pks=10)
    all_pk_names = make_pknames(total_pks)
    packages = PackageInfo[]
    sizehint!(packages, pkgs_no)
    pk_names = sample(all_pk_names, pkgs_no, replace=false)
    for p in pk_names
        push!(packages, make_pkg(p, envs, max_envs))
    end
    return packages
end
export make_pkgs

