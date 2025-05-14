using Test
using ShareAdd
using ShareAdd: all_same_art, invert_dict, module_isloaded, latest_version, list_shared_envs, is_package

@test !all_same_art(["a", "b", "@c"])
@test all_same_art(["@a", "@b", "@c"])
@test all_same_art(["a", "b", "c"])
da = (Dict("a" => ["1", "2", "3"], "b" => ["3", "4", "5"], "c" => ["5", "6", "7", "8"], "e" => ["1", "2", "6", "7", "8"]))
di = invert_dict(da)
dd = Dict("8" => ["c", "e"], "4" => ["b"], "1" => ["a", "e"], "5" => ["b", "c"], "2" => ["a", "e"], "6" => ["c", "e"], "7" => ["c", "e"], "3" => ["a", "b"])
@test di == dd

@test module_isloaded.(["Test", "Aqua", "ShareAdd", "SafeTestsets"]) |> all
@test latest_version(["ShareAdd"])["ShareAdd"] > v"2.0.0"
@test isempty(list_shared_envs("Pkg"))
@test list_shared_envs("Pkg"; std_lib = true) == ["stdlib"]
@test !is_package()