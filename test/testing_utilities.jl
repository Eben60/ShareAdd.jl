module TestUtilities
using ..ShareAdd
using ShareAdd: testfolder_prefix # , cleanup_testenvs
using Random
using TOML

function make_tmp_env(folder)
    name = "$(testfolder_prefix)$(randstring(10))" |> lowercase
    readme = """The enclosing folder "$name" is a temporary one. It was created within a test run, and normally shlould habe been deleted. Please delete it."""
    path = joinpath(folder, name)
    mkdir(path)
    open(joinpath(path, "README.txt"), "w") do io
        print(io, readme)
    end
    return (; name, path)
end
export make_tmp_env

function create_project_toml(env, pkgs)
    contents = Dict("deps" => Dict([name=>uuid for (name, uuid) in pkgs]))
    open(joinpath(env.path, "Project.toml"), "w") do io
        TOML.print(io, contents, sorted=true)
    end
    return nothing
end
export create_project_toml

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
export create_manifest_toml

create_project(env, pkgs) = (create_project_toml(env, pkgs); create_manifest_toml(env, pkgs))
export create_project

end