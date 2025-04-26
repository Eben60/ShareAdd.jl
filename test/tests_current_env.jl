using Test
using ShareAdd
using ShareAdd: current_env

ce = current_env()
@test ce.shared == false
@test ce.pkgs == Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "ShareAdd", "SafeTestsets", "Random", "Pkg"])