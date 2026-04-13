using Test
using TOML
using ShareAdd: _locate_project_file, list_env_pkgs

@testset "locate_project_file" begin
    # Create a temporary directory for each sub-test
    mktempdir() do dir
        # No project file → nothing
        @test isnothing(_locate_project_file(dir))

        # Only Project.toml → finds it
        pt = joinpath(dir, "Project.toml")
        write(pt, "[deps]\n")
        @test _locate_project_file(dir) == pt

        # Add JuliaProject.toml → it takes priority
        jpt = joinpath(dir, "JuliaProject.toml")
        write(jpt, "[deps]\n")
        @test _locate_project_file(dir) == jpt

        # Remove JuliaProject.toml → falls back to Project.toml
        rm(jpt)
        @test _locate_project_file(dir) == pt
    end
end

@testset "list_env_pkgs with JuliaProject.toml" begin
    mktempdir() do dir
        # Empty directory → empty list
        @test list_env_pkgs(dir) == String[]

        # Write a JuliaProject.toml with deps
        jpt = joinpath(dir, "JuliaProject.toml")
        deps = Dict("deps" => Dict("FakePkg1" => "00000000-0000-0000-0000-000000000001",
                                    "FakePkg2" => "00000000-0000-0000-0000-000000000002"))
        open(jpt, "w") do io
            TOML.print(io, deps)
        end

        pkgs = list_env_pkgs(dir)
        @test pkgs == ["FakePkg1", "FakePkg2"]

        # Ensure Project.toml in the same dir is ignored (JuliaProject.toml takes priority)
        pt = joinpath(dir, "Project.toml")
        deps_alt = Dict("deps" => Dict("OtherPkg" => "00000000-0000-0000-0000-000000000003"))
        open(pt, "w") do io
            TOML.print(io, deps_alt)
        end

        pkgs2 = list_env_pkgs(dir)
        @test pkgs2 == ["FakePkg1", "FakePkg2"]  # still reads JuliaProject.toml

        # Remove JuliaProject.toml → falls back to Project.toml
        rm(jpt)
        pkgs3 = list_env_pkgs(dir)
        @test pkgs3 == ["OtherPkg"]
    end
end
