using Test
using ShareAdd
using ShareAdd: check_packages, package_loaded, make_importable

cp = check_packages(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64", "NO_Ssuch_NOnssensse", "PackageCompiler"])
@test Set(cp.inpath_pkgs) == Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "Base64"])
@test cp.inshared_pkgs == [] || ["PackageCompiler"] # could be on target system
@test cp.installable_pkgs == ["PackageCompiler"] || [] # could be on target system
@test cp.unavailable_pkgs == ["NO_Ssuch_NOnssensse"]

cp1 = check_packages(["Test",])
@test cp1.inpath_pkgs == ["Test"]

cp1a = check_packages("Test")
@test cp1a.inpath_pkgs == ["Test"]

@test !package_loaded("NO_Ssuch_NOnssensse")
@test package_loaded("SafeTestsets")
@test package_loaded(["ShareAdd", "SafeTestsets"])
@test !package_loaded(["ShareAdd", "SafeTestsets", "NO_Ssuch_NOnssensse"])
@test make_importable("ShareAdd") == :success
@test make_importable("ShareAdd", "SafeTestsets") == :success
@test_throws ErrorException make_importable("NO_Ssuch_NOnssensse")