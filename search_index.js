var documenterSearchIndex = {"docs":
[{"location":"","page":"General Info","title":"General Info","text":"(Image: License: MIT) (Image: Documentation)  (Image: Build Status)  (Image: Aqua QA)","category":"page"},{"location":"#ShareAdd.jl","page":"General Info","title":"ShareAdd.jl","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"This Julia package is intended for interactive use. It exports the macro @usingany: This macro makes package(s) available, if they are not already, and loads them with using keyword.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"If a package is available in an environment in LOAD_PATH, that's OK.\nIf a package is available in a shared environment, this environment will be pushed into LOAD_PATH.\nOtherwise if it can be installed, you will be prompted to select an environment to install the package(s).\nIf the package is not listed in any registry, an error will be thrown. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"The package also exports several utility functions - see the Exported functions section.","category":"page"},{"location":"#Usage-example","page":"General Info","title":"Usage example","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"While working on your package MyPackage you may temporarily need packages TOML, Plots, and Chairmarks, which however you don't want to add to your package dependencies. You also need Unitful, which is already an installed dependence of MyPackage. TOML is available in the stdlib, Plots you already put into a shared environment @utilities, and Chairmarks is not on your computer yet. Furthermore, from the package BenchmarkTools (available from @utilities as well) we need only the macro @btime and the function save.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"First, you add ShareAdd to your \"main\" (standard) enviroment, making it available at all times:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"]\n(YourEnv) pkg> activate \n  Activating project at `~/.julia/environments/v1.10`\n\n(@v1.10) pkg> add ShareAdd\n(...)\n(@v1.10) pkg> activate . # back to your environment\n(YourEnv) pkg> ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"By that occasion you may also want to clean your standard environment: It is generally not recommended having a lot of packages there.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Now, the only thing you need, is to type into REPL (or adding to your script) the following lines:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd\n@usingany Unitful, TOML, Plots, Chairmarks\n@usingany BenchmarkTools: @btime, save","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"As Chairmarks was not installed yet, you will be asked as to where to install it. You may e.g. add it to your existing @utilities shared environment, or let create a new environment @Chairmarks and put it there. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Afrerwards @utilities (and @Chairmarks, if created) will be added to LOAD_PATH, making their packages available.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Finally, the macros will execute using Unitful, TOML, Plots, Chairmarks resp. using BenchmarkTools: @btime, save - and that's it. Enjoy!","category":"page"},{"location":"#Other-functions-and-usage-cases","page":"General Info","title":"Other functions and usage cases","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"The function make_importable does what it's name says. It is used internally by @usingany, but can be used separately e.g.  if you e.g. want to import a package via import statement instead of using:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd\nmake_importable(\"Foo\")\nimport Foo","category":"page"},{"location":"#Likes-and-dislikes?","page":"General Info","title":"Likes & dislikes?","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Star on GitHub, open an issue, contact me on Julia Discourse.","category":"page"},{"location":"#Credits","page":"General Info","title":"Credits","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Some code and inspiration from EnvironmentMigrators.jl by Mark Kittisopikul. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"The AI from Codeium helped me and bugged me (pun intended).","category":"page"},{"location":"#Copyright-and-License","page":"General Info","title":"Copyright and License","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"© 2024 Eben60","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"MIT License (see separate file LICENSE)","category":"page"},{"location":"docstrings/#Macros","page":"Docstrings","title":"Macros","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ShareAdd]\nOrder   = [:macro, ]","category":"page"},{"location":"docstrings/#ShareAdd.@usingany-Tuple{Any}","page":"Docstrings","title":"ShareAdd.@usingany","text":"@usingany pkg\n@usingany pkg1, pkg2, ... \n@usingany pkg: fn\n@usingany pkg: fn, @mcr, ...\n\nMakes package(s) available, if they are not already, and loads them with using keyword. \n\nIf a package is available in an environment in LOAD_PATH, that's OK.\nIf a package is available in a shared environment, this environment will be pushed into LOAD_PATH.\nOtherwise if package(s) can be installed, you will be prompted to select an environment to install each package.\nIf the package is not listed in any registry, an error will be thrown.\n\nThis macro is exported.\n\n\n\n\n\n","category":"macro"},{"location":"docstrings/#Functions","page":"Docstrings","title":"Functions","text":"","category":"section"},{"location":"docstrings/#Exported-functions","page":"Docstrings","title":"Exported functions","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ShareAdd]\nOrder   = [:function]\nFilter = t -> Base.isexported(ShareAdd, Symbol(t))","category":"page"},{"location":"docstrings/#ShareAdd.delete_shared_env-Tuple{ShareAdd.EnvInfo}","page":"Docstrings","title":"ShareAdd.delete_shared_env","text":"delete_shared_env(env::Union{AbstractString, EnvInfo})\n\nDeletes the shared environment env by erasing it's directory.\n\nReturns nothing.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.delete_shared_pkg-Tuple{AbstractString}","page":"Docstrings","title":"ShareAdd.delete_shared_pkg","text":"delete_shared_pkg(pkg::AbstractString)\n\nDeletes the package pkg from it's shared environment. Deletes this environment if it was the only package there. If the package is present in multiple environments, it will not be deleted and an error will be thrown, suggesting you do it manually.\n\nReturns nothing.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.list_shared_envs-Tuple{}","page":"Docstrings","title":"ShareAdd.list_shared_envs","text":"list_shared_envs() -> Vector{String}\n\nReturns the names of all shared environments.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.list_shared_pkgs-Tuple{}","page":"Docstrings","title":"ShareAdd.list_shared_pkgs","text":"list_shared_pkgs(; all=false) -> Vector{String}\n\nReturns the names of packages in all shared environments. If all=true, also includes packages in @stdlib.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.make_importable-Tuple{Any}","page":"Docstrings","title":"ShareAdd.make_importable","text":"make_importable(pkg::AbstractString)\nmake_importable(pkgs::AbstractVector{<:AbstractString})\nmake_importable(pkg1, pkg2, ...)\n\nChecks  packages (by name only, UUIDs not supported!), prompts to install packages which are not in any shared environment,  and adds relevant shared environments to LOAD_PATH.\n\nmake_importable is used internally by @usingany, but it can be used separately e.g.  if you e.g. want to import a package via import statement instead of using.\n\nReturns :success if the operation was successful, and nothing if the user selected \"Quit. Do Nothing.\" on any of the prompts.\n\nThrows an error on unavailable packages.\n\nExamples\n\njulia> using ShareAdd\njulia> make_importable(\"Foo\")\n:success\njulia> import Foo \n\njulia> using ShareAdd\njulia> make_importable(\"Foo\")\n:success\njulia> using Foo: @bar # @usingany Foo: @bar is not a supported syntax\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.reset_loadpath!-Tuple{}","page":"Docstrings","title":"ShareAdd.reset_loadpath!","text":"reset_loadpath!()\n\nResets the LOAD_PATH to the default values: removes any manually added paths, and resets the load path to the standard values of [\"@\", \"@v#.#\", \"@stdlib\"]. \n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.sh_add-Tuple{AbstractString}","page":"Docstrings","title":"ShareAdd.sh_add","text":"sh_add(env_name::AbstractString; depot = first(DEPOT_PATH)) -> Vector{String}\nsh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH)) -> Vector{String}\nsh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) -> Vector{String}\n\nAdds shared environment(s) to LOAD_PATH, making the corresponding packages all available in the current session.\n\nReturns the list of all packages in the added environments as a Vector{String}.\n\nExamples\n\njulia> sh_add(\"@StatPackages\")\n3-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n\njulia> sh_add([\"@StatPackages\", \"@Makie\"])\n4-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n \"Makie\"\n\njulia> sh_add(\"@StatPackages\", \"@Makie\")\n4-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n \"Makie\"\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.update_shared","page":"Docstrings","title":"ShareAdd.update_shared","text":"update_shared()\nupdate_shared(nm::AbstractString)\nupdate_shared(nm::Vector{AbstractString})\nupdate_shared(env::AbstractString, pkgs::Union{AbstractString, Vector{AbstractString}}) \nupdate_shared(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing) where S <: AbstractString\n\nCalled with no arguments, updates all shared environments.\nCalled with a single argument nm::String starting with \"@\", updates the environment nm (if it exists).\nCalled with a single argument nm::String not starting with \"@\", updates the package nm in all shared environments.\nCalled with a single argument nm::Vector{String}, updates the packages and/or environments in nm.\nCalled with two arguments env and pkgs, updates the package(s) pkgs in the environment env.\n\nReturnes nothing.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#Public-functions","page":"Docstrings","title":"Public functions","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ShareAdd]\nOrder   = [:function]\nFilter = t -> (! Base.isexported(ShareAdd, Symbol(t)) && Base.ispublic(ShareAdd, Symbol(t)))","category":"page"},{"location":"docstrings/#ShareAdd.check_packages-Tuple{Any}","page":"Docstrings","title":"ShareAdd.check_packages","text":"check_packages(packages; depot = first(DEPOT_PATH)) -> NamedTuple\n\nchecks whether packages are available in the current environment, shared environments, or are installable.\n\nReturns a NamedTuple with the following fields:\n\ninpath_pkgs: packages that are already present in some environment in LOAD_PATH\ninshared_pkgs: packages that are available in some shared environments\ninstallable_pkgs: available packages\nunavailable_pkgs: packages that are not available from any registry\nshared_pkgs: Dictionary of packages in shared environments\ncurrent_pr: information about the current environment as @NamedTuple{name::String, shared::Bool}\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.current_env-Tuple{}","page":"Docstrings","title":"ShareAdd.current_env","text":"current_env(; depot = first(DEPOT_PATH)) -> EnvInfo\n\nReturns information about the current active environment as an EnvInfo object.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.env_path","page":"Docstrings","title":"ShareAdd.env_path","text":"env_path(env_name::AbstractString, depot = first(DEPOT_PATH); skipfirstchar = true) -> String\n\nReturns the path of the environment with name env_name.  If skipfirstchar is true, the first character of env_name is skipped,  so that the name of a shared environment can be passed without the leading @.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#ShareAdd.list_shared_packages-Tuple{}","page":"Docstrings","title":"ShareAdd.list_shared_packages","text":"list_shared_packages(;depot = first(DEPOT_PATH)) -> Dict{String, PackageInfo}\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.shared_environments_envinfos-Tuple{}","page":"Docstrings","title":"ShareAdd.shared_environments_envinfos","text":"shared_environments_envinfos(; depot = first(DEPOT_PATH)) -> \n    (; shared_envs::Vector{EnvInfo},\n    envs_folder_path::String, \n    shared_env_names::Vector{String})\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Internal-functions","page":"Docstrings","title":"Internal functions","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ShareAdd]\nOrder   = [:function]\nFilter = t -> ! Base.ispublic(ShareAdd, Symbol(t))","category":"page"},{"location":"docstrings/#ShareAdd.fn2string-Tuple{Any}","page":"Docstrings","title":"ShareAdd.fn2string","text":"converts function or macro name to string\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.optim_set-Tuple{AbstractArray{ShareAdd.PackageInfo}}","page":"Docstrings","title":"ShareAdd.optim_set","text":"optim_set(pks::AbstractArray{<:AbstractString}, envs::AbstractVector{EnvInfo}) -> OptimSet\noptim_set(pkgs::AbstractArray{PackageInfo}) -> OptimSet\n\nFinds the optimum set of environments for the given list of packages.  Optimal is a set of environments with the least number of extraneous packages.  If two sets have the same number of extraneous packages, then the one with the least number of environments is chosen.\n\nThe function is internal.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.prompt2install-Tuple{AbstractVector{<:AbstractString}}","page":"Docstrings","title":"ShareAdd.prompt2install","text":"prompt2install(packages::AbstractVector{<:AbstractString})\nprompt2install(package::AbstractString)\n\nPrompt user to select a shared environment to install a package or packages.\n\nFor a single package, if the user selects an environment, the package will be installed there.  If the user selects \"A new shared environment (you will be prompted for the name)\", the user will be prompted to enter a name for a new environment. \n\nFor multiple packages, the function will be called on each package and the user will be prompted for each package.\n\nThe function will return a vector of NamedTuples, each with field pkg and env,  where pkg is the name of the package and env is the environment where it should be installed.\n\nThe function will return nothing if the user selects \"Quit. Do Nothing.\" on any of the prompts.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Types","page":"Docstrings","title":"Types","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"All types are declared as public","category":"page"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ShareAdd]\nOrder   = [:type, ]","category":"page"},{"location":"docstrings/#ShareAdd.EnvInfo","page":"Docstrings","title":"ShareAdd.EnvInfo","text":"mutable struct EnvInfo\n\nname::String - name of the environment\npath::String - path of the environment's folder\npkgs::Vector{String} - list of packages in the environment\nin_path::Bool - whether the environment is in LOAD_PATH \n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ShareAdd.EnvSet","page":"Docstrings","title":"ShareAdd.EnvSet","text":"struct EnvSet\n\nenvs::Set{String} - set of environment names\nextraneous_pks::Set{String} - (internally used, see optim_set function for details)\nextra_lng::Int - as above\nno_of_sets::Int - as above\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ShareAdd.OptimSet","page":"Docstrings","title":"ShareAdd.OptimSet","text":"mutable struct OptimSet\n\nbest_set::EnvSet - the best set of environments currently found - see optim_set function for details.\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ShareAdd.PackageInfo","page":"Docstrings","title":"ShareAdd.PackageInfo","text":"mutable struct PackageInfo\n\nname::String - name of the package\nenvs::Vector{EnvInfo} - list of environments in which the package is present\nin_path::Bool - whether any of the environments is in LOAD_PATH\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Index","page":"Docstrings","title":"Index","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"","category":"page"}]
}
