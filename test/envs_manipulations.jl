module MakeDelEnvs

using Test
using Pkg
using Aqua
using ShareAdd
using SafeTestsets
using Random
using TOML
using Suppressor

(; envs_folder, main_env, envs_exist) = ShareAdd.env_folders()

const fld_pref = "z2del-0nzj"

function cleanup(fld_pref)
    for f in readdir(envs_folder, join=true)
        startswith(basename(f), fld_pref) && rm(f, recursive=true)
    end
    return nothing
end

function make_tmp_env(folder)
    env_name = "$(fld_pref)$(randstring(10))" |> lowercase
    env_path = joinpath(folder, env_name)
    mkdir(env_path)
    return (; env_name, env_path)
end

# # # # # 

cleanup(fld_pref)

(e1n, e1p) = make_tmp_env(envs_folder)
(e2n, e2p) = make_tmp_env(envs_folder)
(e3n, e3p) = make_tmp_env(envs_folder)




fp1 = "Fakeproj1" => "5a8e0e4a-2ba5-4c89-ac0f-8fb2c9294632"
fp2 = "Fakeproj2" => "07e9b84d-f200-4453-ad65-b39ac92d064c"
fp3 = "Fakeproj3" => "23dda021-51d0-46a8-a609-69cee7c5fb25"

function create_Project_toml(path, deps)
    cont = Dict("deps" => deps)
    open(joinpath(path, "Project.toml"), "w") do io
        TOML.print(io, cont, sorted=true)
    end
    return nothing
end

create_Project_toml(e1p, Dict([fp1,]))
create_Project_toml(e2p, Dict([fp1, fp2, fp3]))

@testset "delete_env" begin
    @suppress begin
    using ShareAdd: delete
    @test isdir(e3p)
    delete("@$(e3n)")
    @test !isdir(e3p)

    @test_throws ErrorException delete(fp1.first)
    delete(fp1.first; inall=true)
    @test !isdir(e1p)
    delete([fp2.first, fp3.first])
    @test !isdir(e2p)

    end # @suppress

end

cleanup(fld_pref)

end

