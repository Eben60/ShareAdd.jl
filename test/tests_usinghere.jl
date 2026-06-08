using Test
using ShareAdd
using Pkg
using Suppressor

const FIXTURE_DIR = joinpath(@__DIR__, "fixtures", "usinghere")

# ---------------------------------------------------------------------------
# Helper: run one fixture-based scenario
#   fixture  — filename inside FIXTURE_DIR
#   in_src   — copy the script into a "src/" sub-directory of the tempdir
#   with_toml — create an empty Project.toml in target_dir before including
#   Returns (active_project_after, tempdir)
# ---------------------------------------------------------------------------
function run_fixture(fixture; in_src=false, with_toml=false)
    original_project = Base.active_project()
    original_load_path = copy(LOAD_PATH)

    # Keep "@", "@stdlib", and any absolute paths.
    # Pkg.test() adds the test environment as an absolute path to LOAD_PATH.
    # We remove "@v#.#" and named shared environments to ensure Example is missing.
    filter!(p -> p == "@" || p == "@stdlib" || isabspath(p), LOAD_PATH)

    result_project = Ref{String}()

    mktempdir() do dir
        # Decide where the script lives and where the target env should be
        script_dir  = in_src ? joinpath(dir, "src") : dir
        target_dir  = dir   # always the tempdir root; if in_src, it's the parent of "src/"
        in_src && mkdir(script_dir)

        dest = joinpath(script_dir, fixture)
        cp(joinpath(FIXTURE_DIR, fixture), dest)

        with_toml && touch(joinpath(target_dir, "Project.toml"))

        try
            @suppress include(dest)
            result_project[] = Base.active_project()
        finally
            Pkg.activate(original_project)
            empty!(LOAD_PATH)
            append!(LOAD_PATH, original_load_path)
        end

        @test dirname(result_project[]) == target_dir
    end
end

# ---------------------------------------------------------------------------
# REPL-guard tests  (direct calls to activate_here, no LOAD_PATH changes needed)
# ---------------------------------------------------------------------------
@test_throws ErrorException ShareAdd.activate_here("REPL[1]", ["Test"])
@test_throws ErrorException ShareAdd.activate_here("none", ["Test"])
@test_throws ErrorException ShareAdd.activate_here("", ["Test"])

# ---------------------------------------------------------------------------
# Macro expansion smoke tests (no side-effects)
# ---------------------------------------------------------------------------
# Expands to a :block
expr = macroexpand(@__MODULE__, :(@usinghere Test))
@test expr.head == :block

# No-argument form has no method — throws on expansion
@test_throws Exception macroexpand(@__MODULE__, :(@usinghere))

# ---------------------------------------------------------------------------
# Scenario 1 — plain dir, no pre-existing Project.toml
# "Example" missing → activate_here creates env in script dir and adds it.
# ---------------------------------------------------------------------------
run_fixture("testusinghere.jl"; in_src=false, with_toml=false)

# ---------------------------------------------------------------------------
# Scenario 2 — plain dir, pre-existing Project.toml
# activate_here switches to the existing env and adds Example.
# ---------------------------------------------------------------------------
run_fixture("testusinghere.jl"; in_src=false, with_toml=true)

# ---------------------------------------------------------------------------
# Scenario 3 — script in src/, no Project.toml in parent
# activate_here should target the *parent* of "src/" (the tempdir root).
# ---------------------------------------------------------------------------
run_fixture("testusinghere.jl"; in_src=true, with_toml=false)

# ---------------------------------------------------------------------------
# Scenario 4 — script in src/, pre-existing Project.toml in parent
# ---------------------------------------------------------------------------
run_fixture("testusinghere.jl"; in_src=true, with_toml=true)

# ---------------------------------------------------------------------------
# Scenario 5 — stdlib-only fixture: Test is always in @stdlib, so
# activate_here must be a no-op and leave the active project unchanged.
# ---------------------------------------------------------------------------
begin
    original_project = Base.active_project()
    original_load_path = copy(LOAD_PATH)
    filter!(p -> p == "@" || p == "@stdlib" || isabspath(p), LOAD_PATH)
    dest = joinpath(mktempdir(), "stdlib_only.jl")
    cp(joinpath(FIXTURE_DIR, "stdlib_only.jl"), dest)
    try
        @suppress include(dest)
        @test Base.active_project() == original_project
    finally
        Pkg.activate(original_project)
        empty!(LOAD_PATH)
        append!(LOAD_PATH, original_load_path)
    end
end

# ---------------------------------------------------------------------------
# Scenario 6 — colon syntax: @usinghere Example: hello
# Verifies the Pkg: fn parse path + that `hello` becomes available.
# ---------------------------------------------------------------------------
begin
    original_project = Base.active_project()
    original_load_path = copy(LOAD_PATH)
    filter!(p -> p == "@" || p == "@stdlib" || isabspath(p), LOAD_PATH)

    mktempdir() do dir
        dest = joinpath(dir, "colon_syntax.jl")
        cp(joinpath(FIXTURE_DIR, "colon_syntax.jl"), dest)
        try
            @suppress include(dest)
            @test dirname(Base.active_project()) == dir
            # `hello` was imported into scope by `using Example: hello`
            @test isdefined(@__MODULE__, :hello)
        finally
            Pkg.activate(original_project)
            empty!(LOAD_PATH)
            append!(LOAD_PATH, original_load_path)
        end
    end
end
