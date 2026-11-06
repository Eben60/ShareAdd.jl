# ShareAdd.jl - AI Agent Technical Reference

## Package Overview

ShareAdd.jl helps reduce clutter in the main Julia shared environment and avoids package incompatibility problems. It allows users to seamlessly use multiple shared or temporary environments. It works by temporarily appending selected shared environments to the `LOAD_PATH`, making their packages available in the current session without permanently adding them as dependencies to the active project.

## Core Architecture

### Technology Stack

- **Language**: Julia (v1.10.8+)
- **Standard Libraries**: `Pkg`, `TOML`, `REPL`
- **Dependencies**: `PrecompileTools.jl`
- **Weak Dependencies / Extensions**: `DefaultApplication.jl` (used for opening file explorers via `@showenv`)

### File Structure (src/)

- `ShareAdd.jl`: Main module definition, includes, and exports.
- `types.jl`: Core data structures like `EnvInfo` and `PackageInfo`.
- `macros.jl`: Implementation of `@usingany`, `@usingtmp`, and `@usinghere` macros, as well as dynamic keyword parsing.
- `here_envs.jl`: Activation logic (`activate_here`) specific to script-local environments for the `@usinghere` macro.
- `env_infos.jl`: Functions to query and manage shared environment states and package availability.
- `envs_interactive.jl`: Interactive prompts and menus (using `REPL.TerminalMenus`) for managing environments (e.g., `tidyup`, `prompt2install`).
- `utils_env.jl`: Environment utilities like `delete` and `reset`.
- `workspace.jl`: Julia v1.12+ workspace resolution, recursively detecting sibling projects.
- `update_packages.jl`: Logic for updating packages/environments, versioned manifest planning and normalization (`plan_mnf`, `make_current_mnf`, `with_versioned_mnf`, `active_mnf_path`), and task-local error/notice tracking (`with_update_tracking`).
- `temporary_envs.jl`: Management and activation of temporary environments.
- `info.jl`: Functions to display environment state to the user.
- `optimset.jl`: Algorithm to find the optimal set of shared environments to cover required packages.
- `AbortableTerminalMenu/`: A customized terminal menu module that supports user cancellation.

### Critical Implementation Patterns

- **Load Path Manipulation**: The primary mechanism is dynamically appending shared environments (e.g., `"@MyEnv"`) to `LOAD_PATH` instead of mutating the active project.
- **Interactive Prompts**: Relies heavily on REPL menus to guide users when a requested package is not immediately available, allowing them to install it into an existing shared environment, create a new one, or abort.
- **Workspace Sibling Resolution**: For Julia 1.12+, it searches upward for `Project.toml` files with `[workspace]` tables to automatically resolve sibling packages and inject them into the `LOAD_PATH`.
- **Versioned Manifest Management**: On package installation and environment updates, `with_versioned_mnf` / `make_current_mnf` prepares and normalizes versioned manifests (`Manifest-vX.Y.toml`). It distinguishes `:shared` mode (tidies up or renames generic `Manifest.toml` files) from `:project` mode (including workspace roots; copies forward without deleting or renaming existing files). Read-only manifest lookup uses `active_mnf_path` (wrapping `Base.project_file_manifest_path`).
- **Task-Local Error & Notice Tracking**: `with_update_tracking` collects update failures (`record_update_error!`) and manifest notices (`report_notice!`) in task-local storage, emitting deduplicated notices and a consolidated warning summary upon completion.
- **Enums for Control Flow**: Uses a custom enum `SkipAskForceEnum` (`SKIPPING`, `ASKING`, `FORCING`) to control interactive vs. programmatic behavior in utilities like `delete()`.
- **Keyword Argument Parsing**: Uses an `AbstractAcceptedKwargs` hierarchy (`UsinganyKwargs`, `UsinghereKwargs`) to cleanly and safely define parameter schemas across multiple macros.
- **NamedTuples**: Frequent use of NamedTuples for returning multiple values from internal functions cleanly.

### Current limitations
   
- Relies on package names only; UUIDs are currently ignored.
- Ignores specific branch, version, or source information of packages that might be specified in `Project.toml` or `Manifest.toml`.
- Unregistered packages cannot be installed via interactive prompts, moved by `tidyup`, or updated by `update` (which warns and skips them).

### Precompilation

- Uses `PrecompileTools.jl` with `@compile_workload` to pre-execute common code paths, significantly reducing time-to-first-execution for the macros and interactive dialogs.

### Exported and public identifiers

**Exported:**
```julia
export @usingany, @usingtmp, @usinghere
export @showenv
export SKIPPING, ASKING, FORCING
```

**Public (not exported):**
Functions: `info`, `update`, `delete`, `reset`, `tidyup`, `make_current_mnf`, `make_importable`
Types: `EnvInfo`, `PackageInfo`
