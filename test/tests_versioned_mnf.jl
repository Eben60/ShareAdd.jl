using Test
using ShareAdd
using ShareAdd: plan_mnf, apply_mnf_plan!, mnf_target, with_versioned_mnf, report_notice!, with_update_tracking,
    versioned_mnf_name, active_mnf_path, make_current_mnf, env_folders, testfolder_prefix, EnvInfo, get_manifest
using Random

const V = v"1.13.0" # the Julia version faked in planner tests
const VN = "Manifest-v1.13.toml"

mnf(ver) = "julia_version = \"$ver\"\nmanifest_format = \"2.0\"\n"

"Create a temporary project dir with `files` (name => contents), and run `f(dir)`."
function with_dir(f, files...; project = "name = \"Foo\"\n")
    return mktempdir() do d
        d = realpath(d)
        isnothing(project) || write(joinpath(d, "Project.toml"), project)
        for (name, content) in files
            write(joinpath(d, name), content)
        end
        f(d)
    end
end

mnf_files(d) = sort!(filter(f -> occursin(r"manifest"i, f), readdir(d)))

levels(plan) = [n.level for n in plan.notices]

@testset "planner: basic cases" begin
    with_dir() do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.action == :proceed
        @test p.steps == [(:touch, VN)]
        @test p.current == VN
    end

    # the standard environment is never versioned
    p = plan_mnf(joinpath(env_folders().envs_folder, "v1.13"); v = V)
    @test p.action == :none

    # the versioned manifest for the current version already exists
    with_dir(VN => "") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.action == :proceed
        @test isempty(p.steps)
        @test isempty(p.notices)
        @test p.current == VN
    end

    # copy the most recent older versioned manifest
    with_dir("Manifest-v1.10.toml" => "a", "Manifest-v1.12.toml" => "b", "Manifest-v1.14.toml" => "c") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:cp, "Manifest-v1.12.toml", VN)]
    end

    # only newer manifests -> empty one
    with_dir("Manifest-v1.14.toml" => "c") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:touch, VN)]
    end

    # actual on-disk file names are used
    with_dir("MANIFEST-v1.12.toml" => "b") do d
        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:cp, "MANIFEST-v1.12.toml", VN)]
    end
end

@testset "planner: skipping cases" begin
    with_dir("JuliaManifest.toml" => "") do d
        for mode in (:shared, :project)
            p = plan_mnf(d; v = V, mode)
            @test p.action == :skip
            @test isempty(p.steps)
            @test levels(p) == [:warn]
        end
    end

    with_dir("JuliaManifest-v1.12.toml" => "", "Manifest.toml" => mnf("1.12.0")) do d
        @test plan_mnf(d; v = V).action == :skip
    end

    with_dir("custom.toml" => ""; project = "name = \"Foo\"\nmanifest = \"custom.toml\"\n") do d
        p = plan_mnf(d; v = V)
        @test p.action == :skip
        @test levels(p) == [:warn]
    end

    with_dir(; project = "this is = = not toml [") do d
        @test plan_mnf(d; v = V).action == :skip
    end

    # generic and versioned manifest for the latest available version differ
    with_dir("Manifest.toml" => mnf("1.12.1"), "Manifest-v1.12.toml" => mnf("1.12.2")) do d
        for mode in (:shared, :project)
            p = plan_mnf(d; v = V, mode)
            @test p.action == :skip
            @test isempty(p.steps)
            @test levels(p) == [:dire]
            @test occursin(mode == :shared ? "renaming" : "copying", p.notices[1].msg)
        end
    end
end

@testset "planner: empty and invalid generic manifest" begin
    with_dir("Manifest.toml" => "") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:rm, "Manifest.toml"), (:touch, VN)]
        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:touch, VN)]
        @test levels(p) == [:info]
    end

    with_dir("Manifest.toml" => "this is = = not toml [") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:mv, "Manifest.toml", "Manifest.toml.invalid"), (:touch, VN)]
        @test :warn in levels(p)

        write(joinpath(d, "Manifest.toml.invalid"), "")
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps[1] == (:mv, "Manifest.toml", "Manifest.toml.invalid-1")

        p = plan_mnf(d; v = V, mode = :project)
        @test p.action == :skip
        @test isempty(p.steps)
    end
end

@testset "planner: generic and versioned manifest for the same version" begin
    same = mnf("1.12.1")

    # identical
    with_dir("Manifest.toml" => same, "Manifest-v1.12.toml" => same) do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:rm, "Manifest.toml"), (:cp, "Manifest-v1.12.toml", VN)]
        @test :warn in levels(p)

        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:cp, "Manifest-v1.12.toml", VN)]
        @test :warn ∉ levels(p)
        @test any(n -> occursin("identical", n.msg), p.notices)
    end

    # differ, and the generic one is for the current version: Pkg ignores it
    with_dir("Manifest.toml" => mnf("1.13.0"), VN => mnf("1.13.1")) do d
        for mode in (:shared, :project)
            p = plan_mnf(d; v = V, mode)
            @test p.action == :proceed
            @test isempty(p.steps)
            @test levels(p) == [:warn]
            @test p.current == VN
        end
    end

    # differ, historical: not reported if the current manifest exists
    with_dir("Manifest.toml" => mnf("1.10.8"), "Manifest-v1.10.toml" => mnf("1.10.9"), VN => "") do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test isempty(p.steps)
        @test isempty(p.notices)
    end

    # differ, historical, current one missing: info only, copy the latest versioned
    with_dir("Manifest.toml" => mnf("1.10.8"), "Manifest-v1.10.toml" => mnf("1.10.9"), "Manifest-v1.12.toml" => mnf("1.12.0")) do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.action == :proceed
        @test p.steps == [(:cp, "Manifest-v1.12.toml", VN)]
        @test :info in levels(p)
        @test :warn ∉ levels(p)
    end
end

@testset "planner: generic manifest without versioned counterpart" begin
    # older (but >= 1.10)
    with_dir("Manifest.toml" => mnf("1.12.3")) do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:mv, "Manifest.toml", "Manifest-v1.12.toml"), (:cp, "Manifest-v1.12.toml", VN)]

        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:cp, "Manifest.toml", VN)]
        @test any(n -> occursin("identical", n.msg), p.notices)
    end

    # for the current version
    with_dir("Manifest.toml" => mnf("1.13.0")) do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:mv, "Manifest.toml", VN)]
        @test p.current == VN

        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:cp, "Manifest.toml", VN)]
    end

    # newer than the running Julia: keep it for that version, never copy it back in time
    with_dir("Manifest.toml" => mnf("1.14.0")) do d
        p = plan_mnf(d; v = V, mode = :shared)
        @test p.steps == [(:mv, "Manifest.toml", "Manifest-v1.14.toml"), (:touch, VN)]

        p = plan_mnf(d; v = V, mode = :project)
        @test p.steps == [(:touch, VN)]
    end

    # old (no julia_version entry, or older than 1.10): not renamed, used as a copy source
    for content in ("", mnf("1.9.4"))
        content == "" && (content = "[deps]\n")
        with_dir("Manifest.toml" => content) do d
            for mode in (:shared, :project)
                p = plan_mnf(d; v = V, mode)
                @test p.steps == [(:cp, "Manifest.toml", VN)]
            end
        end
    end
end

@testset "apply_mnf_plan!" begin
    # shared: rename, then copy forward
    with_dir("Manifest.toml" => mnf("1.12.3")) do d
        r = apply_mnf_plan!(d, plan_mnf(d; v = V, mode = :shared))
        @test r == joinpath(d, VN)
        @test mnf_files(d) == ["Manifest-v1.12.toml", VN]
        @test read(joinpath(d, VN), String) == mnf("1.12.3")
    end

    # project: files are never removed or renamed
    with_dir("Manifest.toml" => mnf("1.12.3")) do d
        r = apply_mnf_plan!(d, plan_mnf(d; v = V, mode = :project))
        @test r == joinpath(d, VN)
        @test mnf_files(d) == [VN, "Manifest.toml"]
        @test read(joinpath(d, VN), String) == mnf("1.12.3")
    end

    # invalid manifest is kept aside
    with_dir("Manifest.toml" => "not = = toml [") do d
        apply_mnf_plan!(d, plan_mnf(d; v = V, mode = :shared))
        @test mnf_files(d) == [VN, "Manifest.toml.invalid"]
    end

    # skipping leaves everything untouched
    with_dir("Manifest.toml" => mnf("1.12.1"), "Manifest-v1.12.toml" => mnf("1.12.2")) do d
        r = @test_logs (:warn,) match_mode = :any apply_mnf_plan!(d, plan_mnf(d; v = V, mode = :shared))
        @test isnothing(r)
        @test mnf_files(d) == ["Manifest-v1.12.toml", "Manifest.toml"]
    end

    # no leftovers of the temporary file
    with_dir("Manifest-v1.12.toml" => mnf("1.12.1")) do d
        apply_mnf_plan!(d, plan_mnf(d; v = V, mode = :project))
        @test sort(readdir(d)) == ["Manifest-v1.12.toml", VN, "Project.toml"]
    end
end

@testset "make_current_mnf" begin
    vname = versioned_mnf_name()
    with_dir() do d
        @test make_current_mnf(d) == joinpath(d, vname)
        @test isfile(joinpath(d, vname))
        @test make_current_mnf(d) == joinpath(d, vname) # idempotent
    end

    with_dir("JuliaManifest.toml" => "") do d
        r = @test_logs (:warn,) match_mode = :any make_current_mnf(d)
        @test isnothing(r)
    end

    @test_throws ErrorException make_current_mnf(joinpath(tempdir(), "no_such_dir_" * randstring(8)))
end

@testset "with_versioned_mnf" begin
    vname = versioned_mnf_name()
    older = VersionNumber(VERSION.major, VERSION.minor - 1)
    prev = "Manifest-v$(older.major).$(older.minor).toml"

    # disabled: nothing is done
    with_dir() do d
        @test with_versioned_mnf(() -> 42, d; enabled = false) == 42
        @test isempty(mnf_files(d))
    end

    # the result is returned, and the manifest is prepared before the operation
    with_dir() do d
        r = with_versioned_mnf(d) do
            @test isfile(joinpath(d, vname))
            :done
        end
        @test r == :done
    end

    # also if the operation throws
    with_dir("Manifest.toml" => mnf("$(older.major).$(older.minor).0"), prev => mnf("$(older.major).$(older.minor).1")) do d
        @test_logs match_mode = :any (:warn,) begin
            @test_throws ErrorException with_versioned_mnf(d) do
                write(joinpath(d, "Manifest.toml"), mnf(VERSION))
                error("Pkg failed")
            end
        end
        @test isfile(joinpath(d, vname))
    end

    # ambiguous manifests are left to Pkg; afterwards what Pkg wrote is normalized
    for mode in (:project, :shared)
        mktempdir() do tmp
            tmp = realpath(tmp)
            if mode == :shared
                d = joinpath(env_folders().envs_folder, testfolder_prefix * lowercase(randstring(10)))
                mkdir(d)
            else
                d = tmp
            end
            try
                write(joinpath(d, "Project.toml"), "name = \"Foo\"\n")
                write(joinpath(d, "Manifest.toml"), mnf("$(older.major).$(older.minor).1"))
                write(joinpath(d, prev), mnf("$(older.major).$(older.minor).2"))
                logs, _ = Test.collect_test_logs() do
                    with_versioned_mnf(d) do
                        @test !isfile(joinpath(d, vname)) # not touched before Pkg runs
                        write(joinpath(d, "Manifest.toml"), mnf(VERSION)) # as Pkg would do
                    end
                end
                @test isfile(joinpath(d, vname))
                @test read(joinpath(d, vname), String) == mnf(VERSION)
                @test isfile(joinpath(d, prev))
                if mode == :shared
                    @test !isfile(joinpath(d, "Manifest.toml"))
                else
                    @test isfile(joinpath(d, "Manifest.toml"))
                    @test any(l -> occursin("identical", l.message), logs)
                end
            finally
                mode == :shared && rm(d; recursive = true)
            end
        end
    end
end

@testset "workspaces" begin
    if VERSION >= v"1.12"
        mktempdir() do d
            d = realpath(d)
            sub = joinpath(d, "sub")
            mkpath(sub)
            write(joinpath(d, "Project.toml"), "name = \"Root\"\n[workspace]\nprojects = [\"sub\"]\n")
            write(joinpath(sub, "Project.toml"), "name = \"Sub\"\n")

            @test mnf_target(sub) == (; dir = d, mode = :project)
            @test mnf_target(d) == (; dir = d, mode = :project)

            with_versioned_mnf(() -> nothing, sub)
            @test isfile(joinpath(d, versioned_mnf_name()))
            @test isempty(mnf_files(sub))

            @test make_current_mnf(sub) == joinpath(d, versioned_mnf_name())
        end
    end

    with_dir() do d
        @test mnf_target(d).dir == d
        @test mnf_target(d).mode == :project
    end
end

@testset "reading manifests has no side effects" begin
    with_dir() do d
        env = EnvInfo(; name = "Foo", path = d, pkgs = Set{String}(), in_path = false, standard_env = false,
            shared = false, temporary = false, active_project = false)
        before = sort(readdir(d))
        @test get_manifest(env) == Dict{String, Any}()
        @test sort(readdir(d)) == before

        write(joinpath(d, "Manifest.toml"), mnf("1.10.8"))
        before = sort(readdir(d))
        @test get_manifest(env)["julia_version"] == "1.10.8"
        @test sort(readdir(d)) == before
    end
end

@testset "notice collection" begin
    logs, _ = Test.collect_test_logs() do
        with_update_tracking() do
            report_notice!(:info, "info1")
            report_notice!(:warn, "warn1")
            report_notice!(:dire, "dire1")
            report_notice!(:warn, "warn1")
            report_notice!(:info, "info1")
            nothing
        end
    end
    msgs = [l.message for l in logs]
    @test length(msgs) == 3 # deduplicated
    @test occursin("dire1", msgs[1])
    @test msgs[2] == "warn1"
    @test msgs[3] == "info1"

    # outside of a tracking context, notices are emitted immediately
    logs, _ = Test.collect_test_logs() do
        report_notice!(:warn, "now")
    end
    @test [l.message for l in logs] == ["now"]

    @test_throws ErrorException report_notice!(:bogus, "x")
    @test !haskey(task_local_storage(), :shareadd_notices)
end

@testset "non-interactive guard" begin
    using ShareAdd: check_packages, make_importable
    if !isinteractive()
        # "Example" is registered; if it is not installed anywhere yet, the dialog would be needed
        if "Example" in check_packages("Example").installable_pkgs
            @test_throws ErrorException make_importable("Example")
        else
            @info "Skipping non-interactive guard test: Example is available in some environment"
        end
    end
end
