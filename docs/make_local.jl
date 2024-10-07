using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=(joinpath(@__DIR__, "../") |> normpath))

# generate documentation locally. 
include("makedocs.jl")
;
