using Test
using ShareAdd
using ShareAdd: stdlib_packages

stp = stdlib_packages()
@test stp isa Vector{String}
@test issorted(stp)
@test "Base64" in stp
@test "UUIDs" in stp
@test !("ShareAdd" in stp)
@test !any(s -> endswith(s, "_jll"), stp)

# Mutating returned vector must not corrupt the internal cache
push!(stp, "FakeStdlib_NotReal")
@test !("FakeStdlib_NotReal" in stdlib_packages())
