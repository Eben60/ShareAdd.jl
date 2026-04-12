using Test
using TOML
using ShareAdd: find_workspace_root, _find_parent_workspace, _samedir,
                workspace_sibling_packages, check_workspace_packages

# Helper: write a Project.toml from a Dict
function write_project(dir, data; filename="Project.toml")
    open(joinpath(dir, filename), "w") do io
        TOML.print(io, data)
    end
end

@testset "Workspace" begin

@testset "_samedir" begin
    mktempdir() do dir
        a = joinpath(dir, "foo")
        mkdir(a)
        @test _samedir(a, a)
        @test _samedir(a * "/", a)   # trailing slash stripped
        @test !_samedir(a, dir)
    end
end

@testset "find_workspace_root" begin
    mktempdir() do root
        # --- Simple workspace: root lists two sub-projects ---
        pkgA_dir = joinpath(root, "PkgA")
        pkgB_dir = joinpath(root, "PkgB")
        mkdir(pkgA_dir)
        mkdir(pkgB_dir)

        # Root Project.toml with workspace section
        write_project(root, Dict(
            "workspace" => Dict("projects" => ["PkgA", "PkgB"])
        ))

        # Sub-project Project.toml files
        write_project(pkgA_dir, Dict(
            "name" => "PkgA",
            "uuid" => "00000000-0000-0000-0000-00000000000a",
            "deps" => Dict("Dep1" => "00000000-0000-0000-0000-0000000000d1")
        ))
        write_project(pkgB_dir, Dict(
            "name" => "PkgB",
            "uuid" => "00000000-0000-0000-0000-00000000000b",
            "deps" => Dict("Dep2" => "00000000-0000-0000-0000-0000000000d2")
        ))

        # find_workspace_root from PkgA should return the root Project.toml
        root_proj = find_workspace_root(joinpath(pkgA_dir, "Project.toml"))
        @test !isnothing(root_proj)
        @test dirname(root_proj) == root

        # find_workspace_root from PkgB should also return root
        root_proj2 = find_workspace_root(joinpath(pkgB_dir, "Project.toml"))
        @test root_proj == root_proj2

        # A project NOT listed in the workspace → nothing
        pkgC_dir = joinpath(root, "PkgC")
        mkdir(pkgC_dir)
        write_project(pkgC_dir, Dict("name" => "PkgC"))
        @test isnothing(find_workspace_root(joinpath(pkgC_dir, "Project.toml")))
    end
end

@testset "find_workspace_root nested" begin
    mktempdir() do outer
        inner_dir = joinpath(outer, "Inner")
        leaf_dir  = joinpath(inner_dir, "Leaf")
        mkpath(leaf_dir)

        # Outer workspace lists Inner
        write_project(outer, Dict(
            "workspace" => Dict("projects" => ["Inner"])
        ))

        # Inner workspace lists Leaf
        write_project(inner_dir, Dict(
            "name" => "Inner",
            "uuid" => "00000000-0000-0000-0000-000000000011",
            "workspace" => Dict("projects" => ["Leaf"])
        ))

        write_project(leaf_dir, Dict(
            "name" => "Leaf",
            "uuid" => "00000000-0000-0000-0000-000000000022"
        ))

        # From Leaf, should walk up through Inner to find Outer as the root
        root_proj = find_workspace_root(joinpath(leaf_dir, "Project.toml"))
        @test !isnothing(root_proj)
        @test dirname(root_proj) == outer
    end
end

@testset "workspace_sibling_packages" begin
    mktempdir() do root
        pkgA_dir = joinpath(root, "PkgA")
        pkgB_dir = joinpath(root, "PkgB")
        mkdir(pkgA_dir)
        mkdir(pkgB_dir)

        write_project(root, Dict(
            "workspace" => Dict("projects" => ["PkgA", "PkgB"])
        ))

        write_project(pkgA_dir, Dict(
            "name" => "PkgA",
            "uuid" => "00000000-0000-0000-0000-00000000000a",
            "deps" => Dict(
                "DepX" => "00000000-0000-0000-0000-0000000000d1",
                "DepY" => "00000000-0000-0000-0000-0000000000d2"
            )
        ))

        write_project(pkgB_dir, Dict(
            "name" => "PkgB",
            "uuid" => "00000000-0000-0000-0000-00000000000b",
            "deps" => Dict(
                "DepZ" => "00000000-0000-0000-0000-0000000000d3"
            )
        ))

        root_pt = joinpath(root, "Project.toml")

        # From PkgA's perspective: siblings are PkgB and its deps
        siblings_a = workspace_sibling_packages(root_pt, joinpath(pkgA_dir, "Project.toml"))
        @test haskey(siblings_a, "PkgB")
        @test haskey(siblings_a, "DepZ")
        @test !haskey(siblings_a, "PkgA")   # current project excluded
        @test !haskey(siblings_a, "DepX")   # current project's deps excluded
        @test !haskey(siblings_a, "DepY")   # current project's deps excluded

        # From PkgB's perspective: siblings are PkgA and its deps
        siblings_b = workspace_sibling_packages(root_pt, joinpath(pkgB_dir, "Project.toml"))
        @test haskey(siblings_b, "PkgA")
        @test haskey(siblings_b, "DepX")
        @test haskey(siblings_b, "DepY")
        @test !haskey(siblings_b, "PkgB")
        @test !haskey(siblings_b, "DepZ")

        # Values should point to the sibling directory
        @test _samedir(siblings_a["PkgB"], pkgB_dir)
        @test _samedir(siblings_b["PkgA"], pkgA_dir)
    end
end

@testset "workspace_sibling_packages with JuliaProject.toml" begin
    mktempdir() do root
        pkgA_dir = joinpath(root, "PkgA")
        pkgB_dir = joinpath(root, "PkgB")
        mkdir(pkgA_dir)
        mkdir(pkgB_dir)

        write_project(root, Dict(
            "workspace" => Dict("projects" => ["PkgA", "PkgB"])
        ))

        # PkgA uses JuliaProject.toml
        write_project(pkgA_dir, Dict(
            "name" => "PkgA",
            "uuid" => "00000000-0000-0000-0000-00000000000a",
        ); filename="JuliaProject.toml")

        write_project(pkgB_dir, Dict(
            "name" => "PkgB",
            "uuid" => "00000000-0000-0000-0000-00000000000b",
        ))

        root_pt = joinpath(root, "Project.toml")

        siblings = workspace_sibling_packages(root_pt, joinpath(pkgB_dir, "Project.toml"))
        @test haskey(siblings, "PkgA")  # discovered via JuliaProject.toml
    end
end

@testset "check_workspace_packages" begin
    mktempdir() do root
        pkgA_dir = joinpath(root, "PkgA")
        pkgB_dir = joinpath(root, "PkgB")
        mkdir(pkgA_dir)
        mkdir(pkgB_dir)

        write_project(root, Dict(
            "workspace" => Dict("projects" => ["PkgA", "PkgB"])
        ))

        write_project(pkgA_dir, Dict(
            "name" => "PkgA",
            "uuid" => "00000000-0000-0000-0000-00000000000a",
            "deps" => Dict("SharedDep" => "00000000-0000-0000-0000-0000000000d1")
        ))

        write_project(pkgB_dir, Dict(
            "name" => "PkgB",
            "uuid" => "00000000-0000-0000-0000-00000000000b",
        ))

        current_pt = joinpath(pkgB_dir, "Project.toml")

        # PkgA and SharedDep are available as workspace siblings
        (ws_pkgs, ws_paths) = check_workspace_packages(["PkgA", "SharedDep", "NoSuchPkg"], current_pt)
        @test Set(ws_pkgs) == Set(["PkgA", "SharedDep"])
        @test haskey(ws_paths, "PkgA")
        @test haskey(ws_paths, "SharedDep")
        @test !haskey(ws_paths, "NoSuchPkg")
    end
end

@testset "no workspace" begin
    # A standalone project with no parent workspace
    mktempdir() do dir
        write_project(dir, Dict(
            "name" => "Standalone",
            "uuid" => "00000000-0000-0000-0000-000000000099"
        ))

        @test isnothing(find_workspace_root(joinpath(dir, "Project.toml")))

        (ws_pkgs, ws_paths) = check_workspace_packages(["Anything"], joinpath(dir, "Project.toml"))
        @test isempty(ws_pkgs)
        @test isempty(ws_paths)
    end
end

end # top-level @testset "Workspace"
