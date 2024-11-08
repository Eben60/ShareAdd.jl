@compile_workload begin
    @usingany Pkg
    @usingany Pkg: add
    check_packages("NO_Ssuch_NOnssensse")

    pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false)], false, missing),
    PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P4"]), false, false, true, false, false), 
        EnvInfo("env4", "", Set(["P2", "P3"]), false, false, true, false, false)], false, false),
    PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)], false, true)]

    optimset = optim_set(pkgs)

end