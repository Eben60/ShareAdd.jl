using ShareAdd
using ShareAdd: cleanup_testenvs

using SafeTestsets

ShareAdd.env_folders(; create=true)

@safetestset "Aqua" include("tests_aqua.jl")

include("testing_utilities.jl")

@safetestset "optimset" include("tests_optimset.jl")
@safetestset "registries" include("tests_registries.jl")
@safetestset "current_env" include("tests_current_env.jl")
@safetestset "check_packages" include("tests_check_packages.jl")
@safetestset "is_minor_version" include("tests_is_minor_version.jl")
@safetestset "stdlib_packages" include("tests_stdlib_packages.jl")
@safetestset "usingany_throws" include("tests_usingany_throws.jl")
@safetestset "info" include("tests_info.jl")
@safetestset "reset" include("tests_reset.jl")
@safetestset "Env Manipulations" include("tests_envs_manipulations.jl")
@safetestset "various tests" include("tests_various.jl")
cleanup_testenvs()