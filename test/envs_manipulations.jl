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

const folder_pref = "z2del-0nzj"

function cleanup(fld_pref)
    for f in readdir(envs_folder, join=true)
        startswith(basename(f), fld_pref) && rm(f, recursive=true)
    end
    return nothing
end

function make_tmp_env(folder)
    name = "$(folder_pref)$(randstring(10))" |> lowercase
    readme = """The enclosing folder "$name" is a temporary one. It was created within a test run, and normally shlould habe been deleted. Please delete it."""
    path = joinpath(folder, name)
    mkdir(path)
    open(joinpath(path, "README.txt"), "w") do io
        print(io, readme)
    end
    return (; name, path)
end


function create_project_toml(env, pkgs)
    contents = Dict("deps" => Dict([name=>uuid for (name, uuid) in pkgs]))
    open(joinpath(env.path, "Project.toml"), "w") do io
        TOML.print(io, contents, sorted=true)
    end
    return nothing
end

function create_manifest_toml(env, pkgs)
    contents = Dict{String, Any}(
        "julia_version" => string(VERSION), 
        "manifest_format" => "2.0", 
        "project_hash" => randstring('0':'9',7) * "e769b4ba1e91fd6e37551f17b91d859eb",
        )
    deps = Dict{String, Any}()
    for pkg in pkgs
        deps[pkg.name] = [Dict(k => string.(v) for (k,v) in pairs(pkg))]
    end
    contents["deps"] = deps

    open(joinpath(env.path, "Manifest.toml"), "w") do io
        TOML.print(io, contents, sorted=true)
    end
    return nothing
end

create_project(env, pkgs) = (create_project_toml(env, pkgs); create_manifest_toml(env, pkgs))

# # # # # 

cleanup(folder_pref)

e1 = make_tmp_env(envs_folder)
e2 = make_tmp_env(envs_folder)
e3 = make_tmp_env(envs_folder)


fp1 = (name="Fakeproj1" , uuid="5a8e0e4a-2ba5-4c89-ac0f-8fb2c9294632", version=v"0.1.2")
fp2 = (name="Fakeproj2" , uuid="07e9b84d-f200-4453-ad65-b39ac92d064c", version=v"1.2.3")
fp3 = (name="Fakeproj3" , uuid="23dda021-51d0-46a8-a609-69cee7c5fb25", version=v"2.3.4")

create_project(e1, [fp1,])
create_project(e2, [fp1, fp2, fp3])

@testset "InfoExtended" begin


    using ShareAdd: pkg_version, info, EnvInfo, shared_environments_envinfos
    @test pkg_version("@$(e1.name)", fp1.name) == VersionNumber(fp1.version)
    @test pkg_version("@$(e2.name)") == Dict(fp.name => VersionNumber(fp.version) for fp in [fp1, fp2, fp3])
    @test isnothing(info(; disp_rslt=false))
    (; env_dict, pkg_dict, envs, pkgs, absent) = info(; disp_rslt=false, ret_rslt=true)
    @test Set([e1.name, e2.name]) ⊆ Set(envs)
    @test Set([fp1.name, fp2.name, fp2.name]) ⊆ Set(pkgs)

    (; env_dict, pkg_dict, envs, pkgs, absent) = info(fp1.name; disp_rslt=false, ret_rslt=true)
    @test [fp1.name] == pkgs
    @test [e1.name, e2.name] |> sort! == envs

    @test env_dict[e1.name] == [fp1.name]
    @test env_dict[e2.name] == [fp1.name]
    @test pkg_dict[fp1.name] == [e1.name, e2.name] |> sort!

    (; env_dict, pkg_dict, envs, pkgs, absent) = info([fp1.name, fp2.name]; disp_rslt=false, ret_rslt=true)
    @test [fp1.name, fp2.name] == pkgs
    @test [e1.name, e2.name] |> sort! == envs

    @test env_dict[e1.name] == [fp1.name]
    @test env_dict[e2.name] == [fp1.name, fp2.name]
    @test pkg_dict[fp1.name] == [e1.name, e2.name] |> sort!
    @test pkg_dict[fp2.name] == [e2.name]

    (; env_dict, pkg_dict, envs, pkgs, absent) = info(["@$(e1.name)", "@$(e2.name)"]; disp_rslt=false, ret_rslt=true)
    @test [fp1.name, fp2.name, fp3.name] == pkgs
    @test [e1.name, e2.name] |> sort! == envs

    @test env_dict[e1.name] == [fp1.name]
    @test env_dict[e2.name] == [fp1.name, fp2.name, fp3.name]
    @test pkg_dict[fp1.name] == [e1.name, e2.name] |> sort!
    @test pkg_dict[fp2.name] == [e2.name]

    (; shared_envs) = shared_environments_envinfos(; std_lib = false)

    (; env_dict, pkg_dict, envs, pkgs, absent) = info("FakeProjectNoteExists"; disp_rslt=false,ret_rslt=true)
    @test "FakeProjectNoteExists" in absent

    @suppress begin
        @test isnothing(info())

    end # @suppress
end

@testset "update" begin
    @suppress begin
    using ShareAdd: update
    @test_throws Pkg.Types.PkgError update(fp3.name) 
    @test_throws Pkg.Types.PkgError update("@$(e2.name)") 


    @test_logs (:warn, r"Package Fake_roj1 not found") match_mode=:any update("Fake_roj1"; warn_if_missing=true)
    @test_logs (:warn, r"are not in the environment") match_mode=:any update("@$(e2.name)", "Fake_roj1"; warn_if_missing=true)
    end # @suppress
end # "update"

@testset "delete_env" begin
    @suppress begin
    using ShareAdd: delete
    @test isdir(e3.path)
    delete("@$(e3.name)")
    @test !isdir(e3.path)

    @test_throws ErrorException delete(fp1.name)
    if VERSION >= v"1.11" # deleting with faked project would throw on 1.10
        delete(fp1.name; inall=true) 
        @test !isdir(e1.path)
        delete([fp2.name, fp3.name])
        @test !isdir(e2.path)
    end
    end # @suppress

end


cleanup(folder_pref)

end

