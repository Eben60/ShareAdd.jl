using Test
using ShareAdd
using ShareAdd: current_env

ce = current_env()
@test ce.shared == false
@test ce.pkgs in [Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "SafeTestsets", "Random", "Pkg"]), 
    Set(["Coverage", "Test", "Aqua", "Suppressor", "TOML", "SafeTestsets", "Random", "Pkg", "ShareAdd"])]