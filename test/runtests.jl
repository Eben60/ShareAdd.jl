using Test
using ShareAdd
using ShareAdd: cleanup_testenvs, testfolder_prefix
using SafeTestsets

ShareAdd.env_folders(; create=true)

# alltests = !(isdefined(@__MODULE__, :complete_tests) && !complete_tests)
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

cleanup_testenvs()