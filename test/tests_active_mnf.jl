using Test
using ShareAdd

# Contract tests for the internal function Base.project_file_manifest_path,
# which ShareAdd relies on (only) via ShareAdd.active_mnf_path.

@test isdefined(Base, :project_file_manifest_path)

@testset "active_mnf_path" begin
    using ShareAdd: active_mnf_path, versioned_mnf_name

    vname = versioned_mnf_name()
    other = "Manifest-v1.9.toml"
    jname = "Julia" * vname

    function with_env(f; files = String[], project = "name = \"Foo\"\n")
        mktempdir() do d
            d = realpath(d)
            isnothing(project) || write(joinpath(d, "Project.toml"), project)
            for fl in files
                write(joinpath(d, fl), "")
            end
            f(d)
        end
    end

    with_env(; project = nothing) do d
        @test isnothing(active_mnf_path(d))
    end

    with_env() do d
        @test isnothing(active_mnf_path(d))
    end

    with_env(; files = ["Manifest.toml"]) do d
        @test active_mnf_path(d) == joinpath(d, "Manifest.toml")
    end

    with_env(; files = ["Manifest.toml", vname]) do d
        @test active_mnf_path(d) == joinpath(d, vname)
    end

    with_env(; files = [vname, jname]) do d
        @test active_mnf_path(d) == joinpath(d, jname)
    end

    with_env(; files = ["JuliaManifest.toml", "Manifest.toml"]) do d
        @test active_mnf_path(d) == joinpath(d, "JuliaManifest.toml")
    end

    with_env(; files = [other]) do d
        @test isnothing(active_mnf_path(d))
    end

    with_env(; files = ["custom.toml", "Manifest.toml"], project = "name = \"Foo\"\nmanifest = \"custom.toml\"\n") do d
        @test active_mnf_path(d) == joinpath(d, "custom.toml")
    end

    if VERSION >= v"1.12"
        mktempdir() do d
            d = realpath(d)
            sub = joinpath(d, "sub")
            subsub = joinpath(sub, "subsub")
            mkpath(subsub)
            write(joinpath(d, "Project.toml"), "name = \"Root\"\n[workspace]\nprojects = [\"sub\"]\n")
            write(joinpath(sub, "Project.toml"), "name = \"Sub\"\n[workspace]\nprojects = [\"subsub\"]\n")
            write(joinpath(subsub, "Project.toml"), "name = \"SubSub\"\n")

            @test isnothing(active_mnf_path(sub))
            write(joinpath(sub, "Manifest.toml"), "")
            write(joinpath(d, vname), "")

            @test active_mnf_path(sub) == joinpath(d, vname) # member -> root's manifest
            @test active_mnf_path(subsub) == joinpath(d, vname) # nested -> outermost root
            @test active_mnf_path(d) == joinpath(d, vname)
        end
    end
end
