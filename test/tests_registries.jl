using Test
using ShareAdd

@testset "is_in_registries" begin
    using ShareAdd: is_in_registries, _reachable_registries

    regs = _reachable_registries()
    @test regs isa AbstractVector
    @test !isempty(regs)

    @test is_in_registries("Unitful")
    @test !is_in_registries("NO_Ssuch_NOnssensse")
    @test is_in_registries(Base.PkgId(ShareAdd).uuid)
    @test !is_in_registries(Base.UUID("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"))
    @test !is_in_registries("Test")
    @test !is_in_registries(Base.PkgId(Test).uuid)
end

@testset "is_addable" begin
    using TOML
    using ShareAdd: is_addable

    # Registered package (String, UUID, Module)
    @test is_addable("ShareAdd")
    @test is_addable("ShareAdd"; include_stdlib = false)
    @test is_addable(Base.PkgId(ShareAdd).uuid)
    @test is_addable(Base.PkgId(ShareAdd).uuid; include_stdlib = false)
    @test is_addable(ShareAdd)
    @test is_addable(ShareAdd; include_stdlib = false)

    # Pure stdlib
    @test is_addable("UUIDs")
    @test !is_addable("UUIDs"; include_stdlib = false)
    @test is_addable("Test")
    @test !is_addable("Test"; include_stdlib = false)
    @test is_addable(Test)
    @test !is_addable(Test; include_stdlib = false)
    @test is_addable(Base.PkgId(Test).uuid)
    @test !is_addable(Base.PkgId(Test).uuid; include_stdlib = false)

    # Registered/upgradable stdlib
    @test is_addable("TOML")
    @test is_addable("TOML"; include_stdlib = false)
    @test is_addable(TOML; include_stdlib = false)

    # Non-existent packages, submodules, & non-package modules
    @test !is_addable("NO_Ssuch_NOnssensse")
    @test !is_addable("NO_Ssuch_NOnssensse"; include_stdlib = false)
    @test !is_addable(Base.UUID("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"))
    @test !is_addable(ShareAdd.AbortableTerminalMenu)
    @test !is_addable(ShareAdd.AbortableTerminalMenu; include_stdlib = false)
    @test !is_addable(Main)
    @test !is_addable(Module())
end

@testset "_is_addable test hook" begin
    using ShareAdd: is_addable, _is_addable

    @test !is_addable("Fakeproj1")

    prev = ShareAdd.IS_TESTING[]
    try
        ShareAdd.IS_TESTING[] = true
        @test _is_addable("Fakeproj1")
        @test !is_addable("Fakeproj1")
        @test !_is_addable("FakeUnregistered")

        ShareAdd.IS_TESTING[] = false
        @test !_is_addable("Fakeproj1")
    finally
        ShareAdd.IS_TESTING[] = prev
    end
end

@testset "public API" begin
    if VERSION >= v"1.11"
        @test Base.ispublic(ShareAdd, :is_addable)
        @test Base.ispublic(ShareAdd, :stdlib_packages)
        @test !Base.isexported(ShareAdd, :is_addable)
        @test !Base.isexported(ShareAdd, :stdlib_packages)
    end
end
