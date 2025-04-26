using Test
using ShareAdd
using ShareAdd: is_minor_version

@test is_minor_version(v"1.2.3", v"1.2.4")
@test is_minor_version(v"1.2.3", v"1.2.3")
@test !is_minor_version(v"1.2.3", v"1.3.0")
@test !is_minor_version(v"1.2.3", v"2.0.0")