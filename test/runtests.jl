using Test
using Aqua
using ShareAdd
using SafeTestsets

ShareAdd.env_folders(; create=true)

alltests = !(isdefined(@__MODULE__, :complete_tests) && !complete_tests)
alltests && Aqua.test_all(ShareAdd)

@testset "optimset" begin
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
end

@safetestset "registries" begin
    using ShareAdd: is_in_registries
    @test is_in_registries("Unitful")
    @test ! is_in_registries("NO_Ssuch_NOnssensse")   
end

@safetestset "current_env" begin
    using ShareAdd: current_env
    ce = current_env()
    @test ce.shared == false
    @test ce.pkgs == Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "SafeTestsets", "Random", "Pkg"])
end

@safetestset "check_packages" begin
    using ShareAdd: check_packages
    cp = check_packages(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64", "NO_Ssuch_NOnssensse", "PackageCompiler"])
    @test Set(cp.inpath_pkgs) == Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64"])
    @test cp.inshared_pkgs == [] || ["PackageCompiler"] # could be on target system
    @test cp.installable_pkgs == ["PackageCompiler"] || [] # could be on target system
    @test cp.unavailable_pkgs == ["NO_Ssuch_NOnssensse"]

    cp1 = check_packages(["Test",])
    @test cp1.inpath_pkgs == ["Test"]

    cp1a = check_packages("Test")
    @test cp1a.inpath_pkgs == ["Test"]

end

@safetestset "is_minor_version" begin
    using ShareAdd: is_minor_version
    @test is_minor_version(v"1.2.3", v"1.2.4")
    @test is_minor_version(v"1.2.3", v"1.2.3")
    @test !is_minor_version(v"1.2.3", v"1.3.0")
    @test !is_minor_version(v"1.2.3", v"2.0.0")
end

@safetestset "stdlib_packages" begin
    using ShareAdd: stdlib_packages
    stp = stdlib_packages()
    @test "Base64" in stp
    @test ! ("ShareAdd" in stp)
end

@safetestset "usingany_throws" begin
    using ShareAdd: @usingany
    @test_throws ArgumentError @macroexpand @usingany 
    @test_throws ArgumentError @macroexpand @usingany update_pkg = true
end

@safetestset "info" begin
    using ShareAdd: all_same_art, invert_dict, pkg_isloaded, latest_version, list_shared_envs, is_package
    @test !all_same_art(["a", "b", "@c"])
    @test all_same_art(["@a", "@b", "@c"])
    @test all_same_art(["a", "b", "c"])
    da = (Dict("a" => ["1", "2", "3"], "b" => ["3", "4", "5"], "c" => ["5", "6", "7", "8"], "e" => ["1", "2", "6", "7", "8"]))
    di = invert_dict(da)
    dd = Dict("8" => ["c", "e"], "4" => ["b"], "1" => ["a", "e"], "5" => ["b", "c"], "2" => ["a", "e"], "6" => ["c", "e"], "7" => ["c", "e"], "3" => ["a", "b"])
    @test di == dd

    @test pkg_isloaded.(["Test", "Aqua", "ShareAdd", "SafeTestsets"]) |> all
    @test latest_version(["ShareAdd"])["ShareAdd"] > v"2.0.0"
    @test isempty(list_shared_envs("Pkg"))
    @test list_shared_envs("Pkg"; std_lib = true) == ["stdlib"]
    @test !is_package()
end

@safetestset "reset" begin
    using ShareAdd: reset
    load_path = copy(Base.LOAD_PATH)
    reset()
    @test Base.LOAD_PATH == ["@", "@v#.#", "@stdlib"]
    # restoring LOAD_PATH
    empty!(Base.LOAD_PATH)
    append!(Base.LOAD_PATH, load_path)
end # @safetestset

include("envs_manipulations.jl")