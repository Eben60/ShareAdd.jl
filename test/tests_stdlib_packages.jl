using Test
using ShareAdd
using ShareAdd: stdlib_packages

stp = stdlib_packages()
@test "Base64" in stp
@test ! ("ShareAdd" in stp)