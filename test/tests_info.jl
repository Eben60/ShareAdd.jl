using Test
using ShareAdd

@testset "info helpers" begin
    using ShareAdd: all_same_art, invert_dict, module_isloaded, list_shared_envs, is_package

    @test !all_same_art(["a", "b", "@c"])
    @test all_same_art(["@a", "@b", "@c"])
    @test all_same_art(["a", "b", "c"])
    da = (Dict("a" => ["1", "2", "3"], "b" => ["3", "4", "5"], "c" => ["5", "6", "7", "8"], "e" => ["1", "2", "6", "7", "8"]))
    di = invert_dict(da)
    dd = Dict("8" => ["c", "e"], "4" => ["b"], "1" => ["a", "e"], "5" => ["b", "c"], "2" => ["a", "e"], "6" => ["c", "e"], "7" => ["c", "e"], "3" => ["a", "b"])
    @test di == dd

    @test module_isloaded.(["Test", "Aqua", "ShareAdd", "SafeTestsets"]) |> all
    @test isempty(list_shared_envs("Pkg"))
    @test list_shared_envs("Pkg"; std_lib = true) == ["stdlib"]
    @test !is_package()
end

@testset "info boolean" begin
    using ShareAdd: info

    @test_throws ErrorException info(; boolean=true)
    @test info("Test"; boolean=true) == true
    @test info("SomeUnknownPackage9999"; boolean=true) == false
    @test info(["Test", "SomeUnknownPackage9999"]; boolean=true) == [true, false]
    @test info(["SomeUnknownPackage9999", "Test"]; boolean=true) == [false, true]
end

@testset "latest_version" begin
    using ShareAdd: latest_version

    # String lookup
    v = latest_version("ShareAdd")
    @test v isa VersionNumber
    @test v > v"2.0.0"
    @test isnothing(latest_version("SomeUnknownPackage9999"))

    # Module lookup (root module, submodule, and non-package modules)
    @test latest_version(ShareAdd) == v
    @test latest_version(ShareAdd.AbortableTerminalMenu) == v
    @test isnothing(latest_version(Main))
    @test isnothing(latest_version(Module()))

    # UUID lookup
    shareadd_uuid = Base.PkgId(ShareAdd).uuid
    @test latest_version(shareadd_uuid) == v
    @test isnothing(latest_version(Base.UUID("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")))

    # Vector lookup (homogeneous String, homogeneous Module, heterogeneous Any, empty typed)
    d_str = latest_version(["ShareAdd", "SomeUnknownPackage9999"])
    @test d_str isa Dict{String, Union{VersionNumber, Nothing}}
    @test d_str["ShareAdd"] == v
    @test isnothing(d_str["SomeUnknownPackage9999"])

    d_mod = latest_version([ShareAdd, Main])
    @test d_mod isa Dict{Module, Union{VersionNumber, Nothing}}
    @test d_mod[ShareAdd] == v
    @test isnothing(d_mod[Main])

    d_any = latest_version([ShareAdd, "SomeUnknownPackage9999", shareadd_uuid])
    @test d_any isa Dict{Any, Union{VersionNumber, Nothing}}
    @test d_any[ShareAdd] == v
    @test d_any[shareadd_uuid] == v
    @test isnothing(d_any["SomeUnknownPackage9999"])

    d_empty = latest_version(String[])
    @test d_empty isa Dict{String, Union{VersionNumber, Nothing}}
    @test isempty(d_empty)
end