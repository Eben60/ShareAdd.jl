using Pkg, TOML

prev_proj = Base.active_project()
Pkg.activate(@__DIR__)
path = joinpath(@__DIR__ , "..") |> normpath

project_toml_path = joinpath(path, "Project.toml")
project_toml = TOML.parsefile(project_toml_path)
parent_proj_name = project_toml["name"]

using Suppressor
@suppress begin
Pkg.develop(;path)
end

complete_tests = false
try
    include("envs_manipulations.jl")

finally
    @suppress begin
    try
        Pkg.rm(parent_proj_name)
    catch
    end
    Pkg.activate(prev_proj)
    end
end
;