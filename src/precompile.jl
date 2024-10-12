@compile_workload begin
    @usingany Pkg

    pkgs = [PackageInfo("P1", [EnvInfo("env1", "", Set(["P1", "P2"]), false, false, true, false, false)], false),
    PackageInfo("P2", [EnvInfo("env2", "", Set(["P2", "P4"]), false, false, true, false, false), 
        EnvInfo("env4", "", Set(["P2", "P3"]), false, false, true, false, false)], false),
    PackageInfo("P3", [EnvInfo("env3", "", Set(["P3"]), false, false, true, false, false)], false)]

    optimset = optim_set(pkgs)

end