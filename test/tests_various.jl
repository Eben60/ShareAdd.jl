using Test
using Suppressor
using ShareAdd
using ShareAdd: nothingtodo, combine4envs, is_shared_environment, env_prefix, env_suffix, getenvinfo, main_env_name

p2is = [
    (;env="@e1", pkg="pk1"),
    (;env="@e2", pkg="pk2"),
    (;env="@e1", pkg="pk3"),
    (;env="@e1", pkg="pk4"),
    (;env="@e3", pkg="pk5"),
    (;env="@e2", pkg="pk6"),
]

@test combine4envs(p2is) == Dict("@e1" => ["pk1", "pk3", "pk4"], "@e3" => ["pk5"], "@e2" => ["pk2", "pk6"])

@suppress begin
@test !nothingtodo(["1"])
@test nothingtodo([])
end

@test env_prefix((; name="blabla", shared=true, standard_env=false)) == "@"
@test env_prefix((; name="@blabla", shared=true, standard_env=false)) == ""
stdenv = getenvinfo(main_env_name(true))
@test env_suffix(stdenv) == " (standard Jula environment)"

