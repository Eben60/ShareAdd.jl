using Test
using ShareAdd
using SafeTestsets

@safetestset "env_set" begin
    using ShareAdd: EnvInfo, env_set
    required_pkgs = ["P1", "P2", "P3"]
    envs = [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false),
            EnvInfo("env2", "", Set(["P2", "P3", "P4"]), false, false, true, false, false)]
    envset = env_set(envs, required_pkgs)
    @test envset.extra_lng == 1
    @test envset.no_of_sets == 2
end

@safetestset "init_optimset" begin
    using ShareAdd: PackageInfo, EnvInfo, init_optimset
    pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false)], false, false),
            PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P3"]), false, false, true, false, false)], false, false),
            PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)], false, false)]
    optimset = init_optimset(pkgs)
    @test optimset.best_set.extra_lng == 0
    @test optimset.best_set.no_of_sets == 3
end

@safetestset "recurse_sets!" begin
    using ShareAdd: PackageInfo, EnvInfo, init_optimset, recurse_sets!
    required_pkgs = ["P1", "P2", "P3"]
    envinfos = [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false),
                EnvInfo("env2", "", Set(["P2", "P3"]), false, false, true, false, false),
                EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)]
    optimset = init_optimset([PackageInfo("P1", envinfos, false, false),
                                        PackageInfo("P2", envinfos, false, false),
                                        PackageInfo("P3", envinfos, false, false)])
    recurse_sets!(optimset, envinfos, required_pkgs)
    @test optimset.best_set.extra_lng == 0
    @test optimset.best_set.no_of_sets == 2
end

@safetestset "optim_set" begin
    using ShareAdd: PackageInfo, EnvInfo, optim_set # , OptimSet, EnvSet, all_same_art
    pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false)], false, false),
            PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P4"]), false, false, true, false, false), 
                EnvInfo("env4", "", Set(["P2", "P3"]), false, false, true, false, false)], false, false),
            PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)], false, false)]
    optimset = optim_set(pkgs)
    @test optimset.extra_lng == 0
    @test optimset.no_of_sets == 2
end

@safetestset "remove_redundant_envs!" begin
    using ShareAdd: PackageInfo, EnvInfo, remove_redundant_envs!
    pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false)], false, false),
            PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P3"]), false, false, true, false, false)], false, false),
            PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)], false, false)]
    result = remove_redundant_envs!(pkgs)
    @test length(result[1].envs) == 1
    @test length(result[2].envs) == 1
    @test length(result[3].envs) == 1
end
