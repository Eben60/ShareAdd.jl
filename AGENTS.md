# ShareAdd.jl - AI Agent Technical Reference

## Agents Behavior

- **Always clarify first** if a user's request is unclear, before starting the actual action.
- **Do not** interpret a question or a review request as an implicit request for action. Example of proper dialogue:
    - *Human*: Is XY a good idea?
    - *Agent*: Yes, XY is good because of A, B, and C. Should I implement it for you?
    - *Human*: Yes, please
- **Do not** update this file unless explicitely requested.
- Use Kaimon MCP where expedient. If it is not available, while you may need it, pause and let me know
- Abbreviation "aopp" means "Ask (if you have any questions) Otherwise Please Proceed"

## Package Overview

ShareAdd.jl helps reduce clutter in the main Julia shared environment and avoids package incompatibility problems. It allows users to seamlessly use multiple shared or temporary environments. It works by temporarily appending selected shared environments to the `LOAD_PATH`, making their packages available in the current session without permanently adding them as dependencies to the active project.

## Core Architecture

### Coding Conventions

*   **Function Signatures**: Unless technically required (e.g., for multiple dispatch), do not supply argument types in the function definition. If specifying types, do not overspecify (e.g., use `Real` instead of `Float64` if appropriate).
*   **Docstrings**: Specify the expected types in the docstring signature. You may also explicitly show the return type. Skip detailed explanations if the function is self-explanatory.

Example:
```
"""
    foo(x::Real) --> Real

Squaring the x
"""
function foo(x)
    return x^2
end
```

*   **Syntax**:
    *   Always start `NamedTuple`s with a semicolon.
    *   Always use a semicolon before keyword arguments in function calls.

Example:
```
# Good
state = (; x = 1, y = 2)
foo(a, b; kwarg1 = 1, kwarg2 = 2)
```

*   **Formatting**: If a Tuple, function argument list, or other comma-separated list spans multiple lines, always add a trailing comma after the last item.

Example:
```
items = (
    item1,
    item2,
    item3,  # trailing comma
)
```

### Technology Stack

- **Language**: Julia (v1.10+)
- **Standard Libraries**: `Pkg`, `TOML`, `REPL`
- **Dependencies**: `PrecompileTools.jl`
- **Weak Dependencies / Extensions**: `DefaultApplication.jl` (used for opening file explorers via `@showenv`)

### File Structure (src/)

- `ShareAdd.jl`: Main module definition, includes, and exports.
- `types.jl`: Core data structures like `EnvInfo` and `PackageInfo`.
- `macros.jl`: Implementation of `@usingany` and `@usingtmp` macros.
- `env_infos.jl`: Functions to query and manage shared environment states and package availability.
- `envs_interactive.jl`: Interactive prompts and menus (using `REPL.TerminalMenus`) for managing environments (e.g., `tidyup`, `prompt2install`).
- `utils_env.jl`: Environment utilities like `delete` and `reset`.
- `workspace.jl`: Julia v1.12+ workspace resolution, recursively detecting sibling projects.
- `update_packages.jl`: Logic for updating packages/environments and handling version-specific manifests.
- `temporary_envs.jl`: Management and activation of temporary environments.
- `info.jl`: Functions to display environment state to the user.
- `optimset.jl`: Algorithm to find the optimal set of shared environments to cover required packages.
- `AbortableTerminalMenu/`: A customized terminal menu module that supports user cancellation.

### Critical Implementation Patterns

- **Load Path Manipulation**: The primary mechanism is dynamically appending shared environments (e.g., `"@MyEnv"`) to `LOAD_PATH` instead of mutating the active project.
- **Interactive Prompts**: Relies heavily on REPL menus to guide users when a requested package is not immediately available, allowing them to install it into an existing shared environment, create a new one, or abort.
- **Workspace Sibling Resolution**: For Julia 1.12+, it searches upward for `Project.toml` files with `[workspace]` tables to automatically resolve sibling packages and inject them into the `LOAD_PATH`.
- **Enums for Control Flow**: Uses a custom enum `SkipAskForceEnum` (`SKIPPING`, `ASKING`, `FORCING`) to control interactive vs. programmatic behavior in utilities like `delete()`.
- **NamedTuples**: Frequent use of NamedTuples for returning multiple values from internal functions cleanly.

### Current limitations
   
- Relies on package names only; UUIDs are currently ignored.
- Ignores specific branch, version, or source information of packages that might be specified in `Project.toml` or `Manifest.toml`.
- Errors on update if a package is not registered (unregistered packages cannot be installed via the interactive prompts).

### Precompilation

- Uses `PrecompileTools.jl` with `@compile_workload` to pre-execute common code paths, significantly reducing time-to-first-execution for the macros and interactive dialogs.

### Exported and public identifiers

**Exported:**
```julia
export @usingany, @usingtmp
export @showenv
export SKIPPING, ASKING, FORCING
```

**Public (not exported):**
Functions: `info`, `update`, `delete`, `reset`, `tidyup`, `make_current_mnf`, `make_importable`
Types: `EnvInfo`, `PackageInfo`
