# ShareAdd.jl - AI Agent Technical Reference

## Agents Behavior

- **Always clarify first** if a user's request is unclear, before starting the actual action.
- **Do not** interpret a question or a review request as an implicit request for action. Example of proper dialogue:
    - *Human*: Is XY a good idea?
    - *Agent*: Yes, XY is good because of A, B, and C. Should I implement it for you?
    - *Human*: Yes, please
- **Do not** update this file unless explicitely requested.
- Abbreviation "aopp" means "Ask (if you have any questions) Otherwise Please Proceed"

## Package Overview

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

### File Structure (src/)


### Developer Diagrams

Diagrams are in the linked files:

- [High-Level User Flow](AGENTS_more_info/Mermaid/high-level_user_flow.md)
- [Callback Execution Sequence](AGENTS_more_info/Mermaid/callback_execution_sequence.md)
- [State Transition Map](AGENTS_more_info/Mermaid/state_transition_map.md)


### Critical Implementation Patterns



### Current limitatins 
   
- Error on update if a package not registered


### Precompilation



### Exported and public identifiers
```julia
export @usingany
```



