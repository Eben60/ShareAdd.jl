using Test
using ShareAdd
using ShareAdd: check_packages

cp = check_packages(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64", "NO_Ssuch_NOnssensse", "PackageCompiler"])
@test Set(cp.inpath_pkgs) == Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64"])
@test cp.inshared_pkgs == [] || ["PackageCompiler"] # could be on target system
@test cp.installable_pkgs == ["PackageCompiler"] || [] # could be on target system
@test cp.unavailable_pkgs == ["NO_Ssuch_NOnssensse"]

cp1 = check_packages(["Test",])
@test cp1.inpath_pkgs == ["Test"]

cp1a = check_packages("Test")
@test cp1a.inpath_pkgs == ["Test"]