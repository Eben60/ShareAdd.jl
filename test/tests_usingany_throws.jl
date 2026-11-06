using Test
using ShareAdd: @usingany, check_loaded_deleted

@test_throws ArgumentError @macroexpand @usingany 
@test_throws ArgumentError @macroexpand @usingany update_pkg = true

@testset "check_loaded_deleted" begin
    @test isnothing(check_loaded_deleted(ErrorException("foo"), ["Example"]))
    @test isnothing(check_loaded_deleted(ArgumentError("not found"), ["NoSuchPackageLoadedXYZ"]))
end