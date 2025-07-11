using Test
using Pkg
using Aqua
using ShareAdd
using ShareAdd: cleanup_testenvs, testfolder_prefix
using Suppressor

(; envs_folder, main_env, envs_exist) = ShareAdd.env_folders()

parent_mod = parentmodule(@__MODULE__)
if isdefined(parent_mod, :TestUtilities)
    using ..TestUtilities
else
    include("testing_utilities.jl")
    using .TestUtilities
end

cleanup_testenvs()

e1 = make_tmp_env(envs_folder)
e2 = make_tmp_env(envs_folder)
e3 = make_tmp_env(envs_folder)
e4 = make_tmp_env(envs_folder)

tmpl = joinpath(@__DIR__, "ShareAdd_testfolder_template")
@test isdir(tmpl)

for f in readdir(tmpl; join=false)
    src = joinpath(tmpl, f)
    dst = joinpath(e4.path, f[7:end])
    cp(src, dst; )
end

fp1 = (name="Fakeproj1" , uuid="5a8e0e4a-2ba5-4c89-ac0f-8fb2c9294632", version=v"0.1.2")
fp2 = (name="Fakeproj2" , uuid="07e9b84d-f200-4453-ad65-b39ac92d064c", version=v"1.2.3")
fp3 = (name="Fakeproj3" , uuid="23dda021-51d0-46a8-a609-69cee7c5fb25", version=v"2.3.4")

create_project(e1, [fp1,])
create_project(e2, [fp1, fp2, fp3])

@testset "InfoExtended" begin

    using ShareAdd: pkg_version, info, shared_environments_envinfos, is_shared_environment, list_shared_envs
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

    info_byenv = @capture_out begin
        @test isnothing(info())
    end

    info_byproj = @capture_out begin
        info(; by_env=false)
    end 

    info_envlisting = @capture_out begin
        info(; listing=:envs)
    end 

    info_pkglisting = @capture_out begin
        info(; listing=:pkgs)
    end

    info_absent = @capture_out begin
        info(["@$(e1.name)", "@NoSuchFakeEnvironment"])
    end

    info_upgradable = @capture_out begin
        info(["@$(e4.name)"]; upgradable=true)
    end

    s1 = "  @$(e1.name)\n" *
    "   => [\"Fakeproj1\"]\n"
    @test occursin(s1, info_byenv)

    s2 = "  @$(e2.name)\n" *
    "   => [\"Fakeproj1\", \"Fakeproj2\", \"Fakeproj3\"]\n"
    @test occursin(s2, info_byenv)

    s3 ="  Fakeproj3\n" *
    "   => [\"@" * e2.name * "\"]\n"
    @test occursin(s3, info_byproj)

    (n1, n2) = [e1.name, e2.name] |> sort
    s4 ="  Fakeproj1\n" *
    "   => [\"@$n1\", \"@$n2\"]"
    @test occursin(s4, info_byproj)

    s5 = raw"^ +\[.*" * "\"$n1\", .*\"$n2\".*"
    r5 = Regex(s5)
    @test occursin(r5, info_envlisting)

    s6 = "\"Fakeproj1\", \"Fakeproj2\", \"Fakeproj3\""
    @test occursin(s6, info_pkglisting)

    s7 = "The following shared envs do not exist:\n" *
    raw".*\[.*\"@NoSuchFakeEnvironment\".*\].*" *
    "\n\nFound pkgs/envs:"
    r7 = Regex(s7)
    @test occursin(r7, info_absent)

    s8 = "  @$(e4.name)\n    ShareAdd: 2.0.0 --> "
    @test occursin(s8, info_upgradable)
    
    @test is_shared_environment("@$(e4.name)")
    @test e1.name in list_shared_envs()

end

@testset "EnvInfo" begin
    using ShareAdd: EnvInfo, sortinghelp1, sortinghelp2, env_info2show, combine4envs, show_2be_installed, tidyup_preproc, tidyup_sortout_pkgs
    ei1 = EnvInfo("@" * e1.name)
    ei2 = EnvInfo("@" * e2.name)
    @test ei2.pkgs == Set([fp1.name, fp2.name, fp3.name])

    @test ei2.in_path == false
    @test ei2.standard_env == false
    @test ei2.shared== true
    @test ei2.temporary == false
    @test ei2.active_project == false

    ei2a = copy(ei2)
    ei2a.pkgs = Set([fp1.name, fp2.name, fp3.name])
    @test ei2a == ei2
    
    @test env_info2show(ei2) == "@$(e2.name)"
    @test env_info2show("@" * "e2.name") == "@" * "e2.name"

    @test sortinghelp1(ei2) == (false, e2.name)
    @test sortinghelp1("@foo") == (false, "foo")
    @test_throws ErrorException sortinghelp1("foo")

    @test sortinghelp2(ei2) == (true, false, false,  e2.name)
    @test sortinghelp2("@foo") == (false, false, false, "foo")
    @test_throws ErrorException sortinghelp2("foo")

    p = [
        (pkg = "Foo", env = "@FOO"),
        (pkg = "Bar", env = "@FOO"),
        (pkg = "Fakeproj1", env = "@FOO"),          
        (pkg = "Fakeproj2", env = ei1),
        (pkg = "Fakeproj3", env = ei1),
    ]
    
    c = combine4envs(p) 
    @test c ==  Dict(
        ei1 => ["Fakeproj2", "Fakeproj3"], 
        "@FOO" => ["Foo", "Bar", "Fakeproj1"],
        )
    
    s2b = show_2be_installed(c)
    @test startswith(s2b[1], "[Foo, Bar, Fakeproj1] ") 
    @test startswith(s2b[2], "[Fakeproj2, Fakeproj3] ") 
    @test endswith(s2b[1], " => @FOO (new env)")
    @test endswith(s2b[2], " => @$(ei1.name)")
    t = tidyup_preproc(ei2)

    @test t.other_pkgs == ["Fakeproj1", "Fakeproj2", "Fakeproj3"]
    @test "Fakeproj1" in t.pkg_in_mult_envs
    @test "SafeTestsets" in t.current_pr.pkgs

    env = ei2
    rqm = Set([2])
    other_pkgs = ["Fakeproj1", "Fakeproj2", "Fakeproj3"]
    pkg_in_mult_envs = ["Fakeproj1"]
    tsp = tidyup_sortout_pkgs(env, rqm, other_pkgs, pkg_in_mult_envs)
    @test tsp == (;removed_pkgs = ["Fakeproj1", "Fakeproj3"], 
                    kept_pkgs = ["Fakeproj2"], 
                    moved_pkgs = ["Fakeproj3"],
                    removed_pkgs_in_multienv = ["Fakeproj1"])
end

@testset "sh_add" begin
    using ShareAdd: EnvSet, sh_add
    lp = LOAD_PATH
    eset = EnvSet(Set([e1.name, e2.name]), Set(), 0,0)
    sh_add(eset)

    @test "@$(e1.name)" in LOAD_PATH
    @test "@$(e2.name)" in LOAD_PATH
    
    filter!(x -> x in lp, LOAD_PATH) # restoring LOAD_PATH
end

@testset "update" begin
    @suppress begin
    using ShareAdd: update
    @test_throws Pkg.Types.PkgError update(fp3.name)
    @test_throws Pkg.Types.PkgError update("@$(e2.name)") 


    @test_logs (:warn, r"Package Fake_roj1 not found") match_mode=:any update("Fake_roj1"; warn_if_missing=true)
    @test_logs (:warn, r"are not in the environment") match_mode=:any update("@$(e2.name)", "Fake_roj1"; warn_if_missing=true)

    if VERSION >= v"1.11" 
        u = update("@$(e4.name)" => "ShareAdd")
        @test isnothing(u)
    end

    end # @suppress
end # "update"

@testset "delete_env" begin
    @suppress begin
    using ShareAdd: delete
    @test isdir(e3.path)
    delete("@$(e3.name)"; inall=true, force=true)
    @test !isdir(e3.path)

    @test isnothing(delete("@$(e4.name)" => "ShareAdd"))
    @test !isdir(e4.path)
    @test_warn r"aborting" delete(fp1.name; inall=SKIPPING, force=SKIPPING)
    if VERSION >= v"1.11" # deleting with faked project would throw on 1.10 
        delete(fp1.name; inall=true) 
        @test !isdir(e1.path)
        delete([fp2.name, fp3.name])
        @test !isdir(e2.path)
    end
    end # @suppress
end

@testset "temporary_env" begin
    using ShareAdd
    using ShareAdd: current_env, is_temporary_env, env_folders, activate_temp
    @suppress begin
    currentpath = current_env().path
    (; main_env) = env_folders()
    Pkg.activate(main_env)
    @test ! is_temporary_env()    
    activate_temp()
    @test is_temporary_env()
    Pkg.activate(currentpath)
    end # suppress
end
