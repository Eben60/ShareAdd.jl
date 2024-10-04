using Test
using ShareAdd

using ShareAdd: PackageInfo, EnvInfo, OptimSet, EnvSet

@testset "optimset" begin
    @testset "env_set" begin
        required_pkgs = ["P1", "P2", "P3"]
        envs = [EnvInfo("env1", "", Set(["P1", "P2"]), false),
                EnvInfo("env2", "", Set(["P2", "P3", "P4"]), false)]
        envset = ShareAdd.env_set(envs, required_pkgs)
        @test envset.extra_lng == 1
        @test envset.no_of_sets == 2
    end

    @testset "init_optimset" begin
        pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false)], false),
                PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P3"]), false)], false),
                PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false)], false)]
        optimset = ShareAdd.init_optimset(pkgs)
        @test optimset.best_set.extra_lng == 0
        @test optimset.best_set.no_of_sets == 3
    end

    @testset "recurse_sets!" begin
        required_pkgs = ["P1", "P2", "P3"]
        envinfos = [EnvInfo("env1", "", Set(["P1", "P2"]), false),
                    EnvInfo("env2", "", Set(["P2", "P3"]), false),
                    EnvInfo("env3", "", Set(["P3"]), false)]
        optimset = ShareAdd.init_optimset([PackageInfo("P1", envinfos, false),
                                          PackageInfo("P2", envinfos, false),
                                          PackageInfo("P3", envinfos, false)])
        ShareAdd.recurse_sets!(optimset, envinfos, required_pkgs)
        @test optimset.best_set.extra_lng == 0
        @test optimset.best_set.no_of_sets == 2
    end

    @testset "optim_set" begin
        pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false)], false),
                PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P4"]), false), 
                    EnvInfo("env4", "", Set(["P2", "P3"]), false)], false),
                PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false)], false)]
        optimset = ShareAdd.optim_set(pkgs)
        @test optimset.best_set.extra_lng == 0
        @test optimset.best_set.no_of_sets == 2
    end

    @testset "remove_redundant_envs!" begin
        pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false)], false),
                PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P3"]), false)], false),
                PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false)], false)]
        result = ShareAdd.remove_redundant_envs!(pkgs)
        @test length(result[1].envs) == 1
        @test length(result[2].envs) == 1
        @test length(result[3].envs) == 1
    end
end
