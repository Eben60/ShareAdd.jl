using Test
using Pkg
using TOML
using ShareAdd
using ShareAdd: UsinganyKwargs, AbstractAcceptedKwargs, UsinghereKwargs
using Suppressor

@testset "parse_kwargs unit tests" begin
    using ShareAdd: parse_kwargs

    # Default struct: no kwargs in args → everything false, index = 0
    (;kwargs, last_kwarg_index) = parse_kwargs((:Foo,), UsinganyKwargs())
    @test kwargs == UsinganyKwargs()
    @test last_kwarg_index == 0

    # Single kwarg parsed correctly
    (;kwargs, last_kwarg_index) = parse_kwargs((:(update_pkg = true), :Foo), UsinganyKwargs())
    @test kwargs.update_pkg == true
    @test kwargs.update_env == false
    @test kwargs.update_all == false
    @test last_kwarg_index == 1

    # Multiple kwargs
    (;kwargs, last_kwarg_index) = parse_kwargs(
        (:(update_pkg = true), :(update_env = true), :Foo), UsinganyKwargs())
    @test kwargs.update_pkg == true
    @test kwargs.update_env == true
    @test kwargs.update_all == false
    @test last_kwarg_index == 2

    # All three kwargs set (no package arg at end)
    (;kwargs, last_kwarg_index) = parse_kwargs(
        (:(update_pkg = true), :(update_env = true), :(update_all = true)), UsinganyKwargs())
    @test kwargs.update_pkg == true
    @test kwargs.update_env == true
    @test kwargs.update_all == true
    @test last_kwarg_index == 3

    # Unknown kwarg → error
    @test_throws ErrorException parse_kwargs((:(bogus_kw = true), :Foo), UsinganyKwargs())

    # Non-boolean value → error
    @test_throws ErrorException parse_kwargs((:(update_pkg = 42), :Foo), UsinganyKwargs())

    # Works generically with UsinghereKwargs
    (;kwargs, last_kwarg_index) = parse_kwargs((:(all = true), :Bar), UsinghereKwargs())
    @test kwargs.all == true
    @test kwargs.only == false
    @test last_kwarg_index == 1

    # Unknown kwarg for UsinghereKwargs (update_pkg is not a valid field)
    @test_throws ErrorException parse_kwargs((:(update_pkg = true), :Bar), UsinghereKwargs())
end

@testset "usingany macro basic tests" begin
    # Test basic expansion without kwargs
    @test macroexpand(@__MODULE__, :(@usingany Test)) isa Expr

    # No args at all -> ArgumentError at expansion time
    @test_throws ArgumentError @macroexpand @usingany
    
    # update_pkg with no packages -> ArgumentError at expansion time
    @test_throws ArgumentError @macroexpand @usingany update_pkg=true

    # Multiple update kwargs together -> ErrorException at expansion time
    @test_throws ErrorException @macroexpand @usingany update_all=true update_env=true
    @test_throws ErrorException @macroexpand @usingany update_all=true update_pkg=true Example
end

@testset "usingany update_pkg integration" begin
    @suppress begin
    original_project = Base.active_project()
    original_load_path = copy(LOAD_PATH)

    fixture_dir = joinpath(@__DIR__, "fixtures", "usingany_kwargs")

    mktempdir() do tmp_dir
        env_path = joinpath(tmp_dir, "fixture")
        
        # Copy fixture contents to the temp dir
        cp(fixture_dir, env_path)

        # Call Pkg.activate on that temporary fixture project
        Pkg.activate(env_path)

        # Record the current version of Example from its Manifest
        mnf_path_before = joinpath(env_path, "Manifest.toml")
        mnf_before = TOML.parsefile(mnf_path_before)
        example_old_version = VersionNumber(mnf_before["deps"]["Example"][1]["version"])

        # include the script from the fixture's copy to actually execute it
        script_path = joinpath(env_path, "src", "usingany-update_pkg.jl")
        include(script_path)

        # Check the Manifest again to ensure the version actually increased
        # Account for versioned manifests.
        mnf_path = ShareAdd.current_mnf(env_path)
        mnf_after = TOML.parsefile(mnf_path)
        ver_after = VersionNumber(mnf_after["deps"]["Example"][1]["version"])
        
        @test ver_after > example_old_version
    end

    # Restore state
    Pkg.activate(original_project)
    empty!(LOAD_PATH)
    append!(LOAD_PATH, original_load_path)
    end # @suppress
end
