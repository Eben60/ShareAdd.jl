var documenterSearchIndex = {"docs":
[{"location":"finally/#Changelog","page":"Changelog, License etc.","title":"Changelog","text":"","category":"section"},{"location":"finally/#Release-2.1.0","page":"Changelog, License etc.","title":"Release 2.1.0","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"2025-01-24 ","category":"page"},{"location":"finally/#Summary","page":"Changelog, License etc.","title":"Summary","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Added a method for ShareAdd.update() and ShareAdd.delete() in form delete(\"@Foo\" => \"bar\")\nSet the lower bound for version-specific manifests now to Julia v1.10.8 (as the feature was backported in Julia)","category":"page"},{"location":"finally/#Release-2.0.3-and-2.0.4","page":"Changelog, License etc.","title":"Release 2.0.3 & 2.0.4","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"2025-01-19 , 2025-01-21 ","category":"page"},{"location":"finally/#Summary-2","page":"Changelog, License etc.","title":"Summary","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Substantially extended tests coverage. \nFixed a minor bug or two.","category":"page"},{"location":"finally/#Releases-2.0.1-and-2.0.2","page":"Changelog, License etc.","title":"Releases 2.0.1 & 2.0.2","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"2025-01-18 ","category":"page"},{"location":"finally/#Fixes","page":"Changelog, License etc.","title":"Fixes","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Workaround for an issue that sometimes occured when running the test suite on a CI server. \nFix a bug with update() call without arguments.","category":"page"},{"location":"finally/#Release-2.0.0","page":"Changelog, License etc.","title":"Release 2.0.0","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"2025-01-18 ","category":"page"},{"location":"finally/#Summary-3","page":"Changelog, License etc.","title":"Summary","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"The utilities for managing environments were completely revamped.","category":"page"},{"location":"finally/#Breaking-changes","page":"Changelog, License etc.","title":"Breaking changes","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"No functions are exported any more, only the both macros @usingany and @usingtmp are exported.\nA number of functions were made internal instead of exported/public or changed names or usage.","category":"page"},{"location":"finally/#New-features","page":"Changelog, License etc.","title":"New features","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"New or renamed public functions with short and easy to note names info, update, delete, and reset provide extended functionalities for managing shared environments.\nSupport for version-specific manifests.","category":"page"},{"location":"finally/#Other-changes","page":"Changelog, License etc.","title":"Other changes","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"This documentation was somewhat restructured.","category":"page"},{"location":"finally/#Releases-0.1.1-..-1.0.4","page":"Changelog, License etc.","title":"Releases 0.1.1 .. 1.0.4","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Work in progress 😓","category":"page"},{"location":"finally/#Initial-release-0.1.0","page":"Changelog, License etc.","title":"Initial release  0.1.0","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"2024-10-13","category":"page"},{"location":"finally/#Likes-and-dislikes?","page":"Changelog, License etc.","title":"Likes & dislikes?","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Star on GitHub, open an issue, contact me on Julia Discourse.","category":"page"},{"location":"finally/#Credits","page":"Changelog, License etc.","title":"Credits","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"Some code and inspiration from EnvironmentMigrators.jl by Mark Kittisopikul. ","category":"page"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"The AI from Codeium helped me and bugged me (pun intended).","category":"page"},{"location":"finally/#Copyright-and-License","page":"Changelog, License etc.","title":"Copyright and License","text":"","category":"section"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"© 2024 Eben60","category":"page"},{"location":"finally/","page":"Changelog, License etc.","title":"Changelog, License etc.","text":"MIT License (see separate file LICENSE)","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"(Image: License: MIT) (Image: Documentation)  (Image: Build Status)  (Image: Coverage)  (Image: Aqua QA)","category":"page"},{"location":"#ShareAdd.jl","page":"General Info","title":"ShareAdd.jl","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"This Julia package is intended for interactive use, and it's aim is to help you in reducing clutter in your main shared environment, and thus avoid package incompatibility problems. It exports two macros: @usingany and @usingtmp, envisioned for two different workflows. The package also provides several utility functions for managing shared environments.","category":"page"},{"location":"#@usingany-macro","page":"General Info","title":"@usingany macro","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"This macro makes package(s) available, if they are not already, and loads them with using keyword.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"If a package is available in an environment in LOAD_PATH, that's OK.\nIf a package is available in a shared environment, this environment will be pushed into LOAD_PATH.\nOtherwise if it can be installed, you will be prompted to select an environment to install the package(s).\nIf the package is not listed in any registry, an error will be thrown. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"# simplest usage case\n@usingany SomePackage","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"For more usage options see @usingany docs .","category":"page"},{"location":"#@usingany-usage-example","page":"General Info","title":"@usingany usage example","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Let's assume, while working on your package MyPackage, we temporarily need packages TOML, Plots, and Chairmarks. However, they shouldn't be added permanently to your package dependencies. Furthermore, from the package BenchmarkTools we need only the macro @btime and the function save. We also need Unitful, which is already an installed dependence of MyPackage.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"TOML is available in the stdlib, Plots and BenchmarkTools you already put into a shared environment @utilities, and Chairmarks is not on your computer yet. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Now, first, you add ShareAdd to your \"main\" (standard) enviroment, making it available at all times:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"]\n(YourEnv) pkg> activate \n  Activating project at `~/.julia/environments/v1.11`\n\n(@v1.11) pkg> add ShareAdd\n(...)\n(@v1.11 pkg> activate . # back to your environment\n(YourEnv) pkg> ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"By that occasion you may also want to clean your standard environment: It is generally not recommended having a lot of packages there.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Now, the only thing you need is to type into REPL (or adding to your script) the following lines:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd\n@usingany Unitful, TOML, Plots, Chairmarks\n@usingany BenchmarkTools: @btime, save","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"As Chairmarks was not installed yet, you will be asked as to where to install it. You may e.g. add it to your existing @utilities shared environment, or let create a new environment @Chairmarks and put it there. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Afrerwards @utilities (and @Chairmarks, if created) will be added to LOAD_PATH, making their packages available.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Finally, the macros will execute using Unitful, TOML, Plots, Chairmarks resp. using BenchmarkTools: @btime, save - and that's it. Enjoy!","category":"page"},{"location":"#@usingany-with-updates","page":"General Info","title":"@usingany with updates","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"By setting the corresponding kwarg, it is possible to first update the packages and/or environments prior to execution of import. E.g. the following command would update the packages Pkg1, Pkg2 in their shared environments:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd\n@usingany update_pkg = true Pkg1, Pkg2","category":"page"},{"location":"#@usingany-without-explicitly-calling-@usingany","page":"General Info","title":"@usingany without explicitly calling @usingany","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"ShareAdd.jl can be combined nicely with BasicAutoloads.jl. See this Discourse post to learn how get packages silently loaded if you call their functions in the REPL - e.g. if you type mean([1,2,3]) or 1.55u\"V\". ","category":"page"},{"location":"#Versioned-manifests","page":"General Info","title":"Versioned manifests","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"If currently used Julia version supports versioned manifests (i.e. >= v1.11), then on any updates using ShareAdd package (see ShareAdd.update), a versioned manifest will be created in each updated env. The function ShareAdd.make_current_mnf can also be used to create a versioned manifest in a specified environment without updating it.","category":"page"},{"location":"#@usingtmp-macro","page":"General Info","title":"@usingtmp macro","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"This macro activates a temporary environment, optionally installs packages into it, and loads them with using keyword. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"If current environment is already a temporary one, environment is not changed.\nIf current env was a project (not package!), a temporary env will be activated.\nIf current env was a package (under development), e.g. MyPkg, a temporary env will be activated, AND MyPkg will be dev-ed in that temporary env. ","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"Thу last one is actually the interesting case, as you can continue to work on MyPkg, while temporarily having additional packages available.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"If @usingtmp was called with arguments, the corresponding packages will be installed into that temporary env,  and imported with using keyword.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd\n@usingtmp Foo, Bar\n@usingtmp Baz: quux","category":"page"},{"location":"#Some-other-functions-and-usage-cases","page":"General Info","title":"Some other functions and usage cases","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"The functions ShareAdd.info(), ShareAdd.update(), ShareAdd.delete() do what their names say.","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"The function ShareAdd.make_importable also does what it says. It is used internally by @usingany, but it can also be used separately in special cases, e.g. if you need using A as B syntax, or want to import a package via import statement instead of using:","category":"page"},{"location":"","page":"General Info","title":"General Info","text":"using ShareAdd: make_importable\nmake_importable(\"Foo\")\nimport Foo","category":"page"},{"location":"#Reference","page":"General Info","title":"Reference","text":"","category":"section"},{"location":"#Exported-macros","page":"General Info","title":"Exported macros","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Modules = [ShareAdd]\nOrder   = [:macro, ]","category":"page"},{"location":"#ShareAdd.@usingany-Tuple","page":"General Info","title":"ShareAdd.@usingany","text":"@usingany pkg\n@usingany pkg1, pkg2, ... \n@usingany pkg: fn\n@usingany pkg: fn, @mcr, ... \n@usingany kwarg = true [pkg...]\n\nMakes package(s) available, if they are not already, and loads them with using keyword. \n\nIf a package is available in an environment in LOAD_PATH, that's OK.\nIf a package is available in a shared environment, this environment will be pushed into LOAD_PATH.\nOtherwise if package(s) can be installed, you will be prompted to select an environment to install each package.\nIf the package is not listed in any registry, an error will be thrown.\n\nThe macro can be called with keyword arguments:\n\nupdate_pkg::Bool: if set to true, first updates the package(s) to be imported by the macro\nupdate_env::Bool: first update the shared environments currently in the LOAD_PATH\nupdate_all::Bool: first update the package to be imported in ALL shared environments where it is present\n\nIf Julia version supports versioned manifests, on any updates a versioned manifest will be created in each updated env. See also make_current_mnf and update.\n\nIf update_all or update_env kwarg is set, @usingany can be called without specifying any package(s) for import.  If update_pkg kwarg is set, package(s) to import must be specified.\n\nThis macro is exported.\n\nExamples\n\njulia> @usingany Foo, Bar\njulia> @usingany Baz: quux\njulia> @usingany update_all = true\njulia> @usingany update_pkg = true Qux\n\n\n\n\n\n","category":"macro"},{"location":"#ShareAdd.@usingtmp-Tuple{}","page":"General Info","title":"ShareAdd.@usingtmp","text":"@usingtmp \n@usingtmp pkg\n@usingtmp pkg1, pkg2, ... \n@usingtmp pkg: fn\n@usingtmp pkg: fn, @mcr, ...\n\nActivates a temporary environment, optionally installs packages into it and loads them with using keyword. \n\nIf current environment is a temporary one, environment is not changed.\nIf current env was a project (not package!), a temporary env will be activated.\nIf current env was a package (under development), e.g. MyPkg, a temporary env will be activated, AND MyPkg will be dev-ed in that temporary env.\n\nAfterwards, if @usingtmp was called with arguments, the corresponding packages will be installed into that temporary env,  and imported with using keyword.\n\nThis macro is exported.\n\n\n\n\n\n","category":"macro"},{"location":"#Public-functions","page":"General Info","title":"Public functions","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Modules = [ShareAdd]\nOrder   = [:function]\nFilter = t -> (! Base.isexported(ShareAdd, nameof(t)) && Base.ispublic(ShareAdd, nameof(t)))","category":"page"},{"location":"#ShareAdd.current_env-Tuple{}","page":"General Info","title":"ShareAdd.current_env","text":"current_env(; depot = first(DEPOT_PATH)) -> EnvInfo\n\nReturns information about the current active environment as an EnvInfo object.\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.delete-Tuple{AbstractVector{<:AbstractString}}","page":"General Info","title":"ShareAdd.delete","text":"delete(nms::Union{String, Vector{String}}; inall=false, force = false) -> nothing\ndelete(nm::AbstractString; inall=false, force = false) -> nothing\ndelete(p::Pair{<:AbstractString, <:AbstractString}; force = false) -> nothing\n\nDeletes shared envs, or packages therein.\n\nIf the provided argument is name(s) of shared environment(s), as specified by leading \"@\" in the names(s): then  deletes the shared environment(s) by erasing their directory.\n\nOtherwise, the provided name(s) are considered package names: then for each package pkg deletes it from it's shared environment.  Afterwards deletes this environment if it was the only package there.\n\nYou can also specify both the env and the package in form  \"@Foo\" => \"bar\"\n\nKeyword arguments\n\ninall=false: If set to true, would delete package from multiple environments. Has no effect, if provided nms is/are env name(s).\nforce=false: If set to true, would delete the env or package from a shared env even if the env is in path, and package is currently loaded.\n\nExamples\n\njulia> ShareAdd.delete(\"@TrialPackages\")\njulia> ShareAdd.delete([\"UnusedPkg\", \"UselessPkg\"]; inall=true)\njulia> ShareAdd.delete(\"@Foo\" => \"bar\")\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.info-Tuple{AbstractString}","page":"General Info","title":"ShareAdd.info","text":"info(nms::Union{Nothing, String, Vector{String}} = nothing; \n    by_env=true, listing=nothing, std_lib=false, upgradable=false, disp_rslt=true, ret_rslt=false)\n\nPrints out and/or returns information about shared environments.\n\nArgument\n\nnms: Name(s) of package(s) or environment(s) to return the information on. Environment names must start with \"@\". Package and env names cannot be provided together in one array.\n\nKeyword arguments\n\nby_env=true: whether to print out results as a Dict of pairs like @env => [pkg1, ...], or pkg => [@env1, ...]. Has no effect on returned (if any) results.\nlisting=nothing: this kwarg can be nothing, :envs, or :pkgs. If one of these two Symbols is provided, the result is printed as a vector of envs or pkgs, resp. In this case by_env is ignored. Has no effect on returned (if any) results\nupgradable=false: if true, all other kwargs will be ignored, and only upgradable packages with installed vs. most recent versions will be printed by environment. \ndisp_rslt=true: whether to print out results.\nret_rslt=false: whether the function returns anything. If set to true, it returns a NamedTuple (; env_dict, pkg_dict, envs, pkgs, absent), where the two first elements are  Dicts with keywords correspondingly by env or by pkg; envs and pkgs are vectors of  respective elements, and absent are those names provided through the nms argument, which  are not contained in the shared envs. Names of envs in the returned data are without leading \"@\".\n\nThis function is public, but not exported, as to avoid possible name conflicts. \n\n# Examples\n\njulia> ShareAdd.info([\"BenchmarkTools\", \"Chairmarks\"])\nThe following packages are not in any shared env:\n    [\"Chairmarks\"]\n\nFound pkgs/envs:\n  @BenchmarkTools\n   => [\"BenchmarkTools\"]\n  @Tools\n   => [\"BenchmarkTools\"]\n\njulia> ShareAdd.info([\"DataFrames\", \"CSV\"]; by_env=false)\n  CSV\n   => [\"@DataFrames\"]\n  DataFrames\n   => [\"@DataFrames\"]\n\njulia> ShareAdd.info(\"StaticArrays\"; upgradable=true)\n  @StaticArrays\n    StaticArrays: 1.9.8 --> 1.9.10   \n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.make_current_mnf-Tuple{Any}","page":"General Info","title":"ShareAdd.make_current_mnf","text":"make_current_mnf(path_or_name) -> path\nmake_current_mnf(; current::Bool) -> path\nmake_current_mnf(env::EnvInfo) -> path\n\nCreates a versioned manifest\n\nIf called make_current_mnf(; current=true), the current environment will be processed by this function. \n\npath_or_name can name of a shared environment starting with @, or a path to any environment.\n\nIf currently executed Julia version doesn't support version-specific manifests, do nothing.\nElse, if a versioned manifest for current Julia already exists, do nothing.\nElse, if the environment is the main shared env for the current Julia version (e.g. \"@v1.11\" for Julia v1.11), do nothing.\nElse, is a (versioned) manifest for an older Julia exists in the given directory, copy it to a file named according to the current Julia version, e.g. Manifest-v1.11.toml.\nElse, create empty one.\n\nReturns path to the created or existing manifest.\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.make_importable-Tuple{Any}","page":"General Info","title":"ShareAdd.make_importable","text":"make_importable(pkg::AbstractString)\nmake_importable(pkgs::AbstractVector{<:AbstractString})\nmake_importable(pkg1, pkg2, ...)\nmake_importable(::Nothing) => :success\n\nChecks  packages (by name only, UUIDs not supported!), prompts to install packages which are not in any shared environment,  and adds relevant shared environments to LOAD_PATH.\n\nmake_importable is used internally by @usingany, but it can be used separately e.g.  if you e.g. want to import a package via import statement instead of using.\n\nReturns :success if the operation was successful, and nothing if the user selected \"Quit. Do Nothing.\" on any of the prompts.\n\nThrows an error on unavailable packages.\n\nExamples\n\njulia> using ShareAdd\njulia> make_importable(\"Foo\")\n:success\njulia> import Foo \n\njulia> using ShareAdd\njulia> make_importable(\"Foo\")\n:success\njulia> using Foo: bazaar as baz  # @usingany Foo: bazaar as baz is not a supported syntax\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.reset-Tuple{}","page":"General Info","title":"ShareAdd.reset","text":"reset()\n\nResets the LOAD_PATH to it's default value of [\"@\", \"@v#.#\", \"@stdlib\"], thus removing any manually added paths. \n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.sh_add-Tuple{AbstractString}","page":"General Info","title":"ShareAdd.sh_add","text":"sh_add(env_name::AbstractString; depot = first(DEPOT_PATH)) -> Vector{String}\nsh_add(env_names::AbstractVector{<:AbstractString}; depot = first(DEPOT_PATH)) -> Vector{String}\nsh_add(env_name::AbstractString, ARGS...; depot = first(DEPOT_PATH)) -> Vector{String}\n\nAdds shared environment(s) to LOAD_PATH, making the corresponding packages all available in the current session.\n\nReturns the list of all packages in the added environments as a Vector{String}.\n\nExamples\n\njulia> using ShareAdd: sh_add\njulia> sh_add(\"@StatPackages\")\n3-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n\njulia> sh_add([\"@StatPackages\", \"@Makie\"])\n4-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n \"Makie\"\n\njulia> sh_add(\"@StatPackages\", \"@Makie\")\n4-element Vector{String}:\n \"Arrow\"\n \"CSV\"\n \"DataFrames\"\n \"Makie\"\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"method"},{"location":"#ShareAdd.update","page":"General Info","title":"ShareAdd.update","text":"update()\nupdate(nm::AbstractString)\nupdate(nm::Vector{<:AbstractString})\nupdate(env::AbstractString, pkgs::Union{AbstractString, Vector{<:AbstractString}}) \nupdate(env::EnvInfo, pkgs::Union{Nothing, S, Vector{S}} = Nothing) where S <: AbstractString\nupdate(p::Pair{<:AbstractString, <:AbstractString})\n\nCalled with no arguments, updates all shared environments.\nCalled with a single argument nm::String starting with \"@\", updates the shared environment nm.\nCalled with a single argument nm::String not starting with \"@\", updates the package nm in all shared environments.\nCalled with a single argument nm::Vector{String}, updates the packages and/or environments in nm.\nCalled with two arguments env and pkgs, updates the package(s) pkgs in the environment env.\nCalled with an argument env => pkg, updates the package pkg in the environment env.\n\nIf Julia version supports version-specific manifest, then on any updates a versioned manifest will be created in each updated env. See also make_current_mnf.\n\nReturnes nothing.\n\nExamples\n\njulia> ShareAdd.update(\"@StatPackages\")\njulia> ShareAdd.update(\"@Foo\" => \"bar\")\n\nThis function is public, not exported.\n\n\n\n\n\n","category":"function"},{"location":"#Public-types","page":"General Info","title":"Public types","text":"","category":"section"},{"location":"","page":"General Info","title":"General Info","text":"Modules = [ShareAdd]\nOrder   = [:type, ]\nFilter = t -> (! Base.isexported(ShareAdd, nameof(t)) && Base.ispublic(ShareAdd, nameof(t)))","category":"page"},{"location":"#ShareAdd.EnvInfo","page":"General Info","title":"ShareAdd.EnvInfo","text":"mutable struct EnvInfo\nEnvInfo(name::AbstractString) -> EnvInfo\n\nname::String - name of the environment\npath::String - path of the environment's folder\npkgs::Vector{String} - list of packages in the environment\nin_path::Bool - whether the environment is in LOAD_PATH \n\nExamples\n\njulia> ShareAdd.EnvInfo(\"@DocumenterTools\")\nShareAdd.EnvInfo(\"DocumenterTools\", \"/Users/eben60/.julia/environments/DocumenterTools\", Set([\"DocumenterTools\"]), false, false, true, false, false)\n\n\n\n\n\n","category":"type"},{"location":"#ShareAdd.PackageInfo","page":"General Info","title":"ShareAdd.PackageInfo","text":"mutable struct PackageInfo\n\nname::String - name of the package\nenvs::Vector{EnvInfo} - list of environments in which the package is present\nin_path::Bool - whether any of the environments is in LOAD_PATH\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Internal-types","page":"Internal functions and Index","title":"Internal types","text":"","category":"section"},{"location":"docstrings/","page":"Internal functions and Index","title":"Internal functions and Index","text":"Modules = [ShareAdd]\nOrder   = [:type, ]\nFilter = t -> ! Base.ispublic(ShareAdd, nameof(t))","category":"page"},{"location":"docstrings/#ShareAdd.EnvSet","page":"Internal functions and Index","title":"ShareAdd.EnvSet","text":"struct EnvSet\n\nenvs::Set{String} - set of environment names\nextraneous_pks::Set{String} - (internally used, see optim_set function for details)\nextra_lng::Int - as above\nno_of_sets::Int - as above\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ShareAdd.OptimSet","page":"Internal functions and Index","title":"ShareAdd.OptimSet","text":"mutable struct OptimSet\n\nbest_set::EnvSet - the best set of environments currently found - see optim_set function for details.\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#Internal-functions","page":"Internal functions and Index","title":"Internal functions","text":"","category":"section"},{"location":"docstrings/","page":"Internal functions and Index","title":"Internal functions and Index","text":"Modules = [ShareAdd]\nOrder   = [:function]\nFilter = t -> ! Base.ispublic(ShareAdd, nameof(t))","category":"page"},{"location":"docstrings/#ShareAdd.activate_temp-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.activate_temp","text":"activate_temp()\n\nIf current environment is a temporary one, does nothing. Otherwise activates a temporary environment.  If the initial environment was a package (under development),  makes this package available in the new environment by calling Pkg.develop.\n\nReturns nothing.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.check_packages-Tuple{Any}","page":"Internal functions and Index","title":"ShareAdd.check_packages","text":"check_packages(packages; depot = first(DEPOT_PATH)) -> NamedTuple\n\nchecks whether packages are available in the current environment, shared environments, or are installable.\n\nReturns a NamedTuple with the following fields:\n\ninpath_pkgs: packages that are already present in some environment in LOAD_PATH\ninshared_pkgs: packages that are available in some shared environments\ninstallable_pkgs: available packages\nunavailable_pkgs: packages that are not available from any registry\nshared_pkgs: Dictionary of packages in shared environments\ncurrent_pr: information about the current environment as @NamedTuple{name::String, shared::Bool}\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.delete_shared_env-Tuple{ShareAdd.EnvInfo}","page":"Internal functions and Index","title":"ShareAdd.delete_shared_env","text":"delete_shared_env(env::Union{AbstractString, EnvInfo}; force = false)\n\nDeletes the shared environment env by erasing it's directory. Set force=true if you want to delete the environment even if it is currently in LOAD_PATH.\n\nReturns nothing.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.delete_shared_pkg-Tuple{AbstractString}","page":"Internal functions and Index","title":"ShareAdd.delete_shared_pkg","text":"delete_shared_pkg(pkg::AbstractString; inall=false)\n\nDeletes the package pkg from it's shared environment. Deletes this environment if it was the only package there. If the package may be present in multiple environments, and you want to delete it from all of them, set inall=true. Set force=true if you want to delete the package even if it is currently loaded.\n\nReturns nothing.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.env_folders-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.env_folders","text":"env_folders(; depot = first(DEPOT_PATH), create=false) -> \n    (; envs_folder, main_env, envs_exist)\n\nReturns a named tuple containing the path to the main folder holding all share environments, the path to the main shared environment, and a boolean indicating whether the main environment folder exists.\n\nIf create=true, the main environment folder will be created if it does not exist.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.env_path","page":"Internal functions and Index","title":"ShareAdd.env_path","text":"env_path(env_name::AbstractString, depot = first(DEPOT_PATH); skipfirstchar = true) -> String\n\nReturns the path of the environment with name env_name.  If skipfirstchar is true, the first character of env_name is skipped,  so that the name of a shared environment can be passed without the leading @.\n\n\n\n\n\n","category":"function"},{"location":"docstrings/#ShareAdd.fn2string-Tuple{Any}","page":"Internal functions and Index","title":"ShareAdd.fn2string","text":"converts function or macro name to string\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.list_shared_envs-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.list_shared_envs","text":"list_shared_envs() -> Vector{String}\nlist_shared_envs(pkg_name) -> Vector{String}\n\nReturns the names of all shared environments (if called without an argument), or  the environment(s) containing the package pkg_name.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.list_shared_packages-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.list_shared_packages","text":"list_shared_packages(;depot = first(DEPOT_PATH)) -> Dict{String, PackageInfo}\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.optim_set-Tuple{AbstractArray{ShareAdd.PackageInfo}}","page":"Internal functions and Index","title":"ShareAdd.optim_set","text":"optim_set(pks::AbstractArray{<:AbstractString}, envs::AbstractVector{EnvInfo}) -> OptimSet\noptim_set(pkgs::AbstractArray{PackageInfo}) -> OptimSet\n\nFinds the optimum set of environments for the given list of packages.  Optimal is a set of environments with the least number of extraneous packages.  If two sets have the same number of extraneous packages, then the one with the least number of environments is chosen.\n\nThe function is internal.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.prompt2install-Tuple{AbstractVector{<:AbstractString}}","page":"Internal functions and Index","title":"ShareAdd.prompt2install","text":"prompt2install(packages::AbstractVector{<:AbstractString})\nprompt2install(package::AbstractString)\n\nPrompt user to select a shared environment to install a package or packages.\n\nFor a single package, if the user selects an environment, the package will be installed there.  If the user selects \"A new shared environment (you will be prompted for the name)\", the user will be prompted to enter a name for a new environment. \n\nFor multiple packages, the function will be called on each package and the user will be prompted for each package.\n\nThe function will return a vector of NamedTuples, each with field pkg and env,  where pkg is the name of the package and env is the environment where it should be installed.\n\nThe function will return nothing if the user selects \"Quit. Do Nothing.\" on any of the prompts.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.shared_environments_envinfos-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.shared_environments_envinfos","text":"shared_environments_envinfos(; depot = first(DEPOT_PATH)) -> \n    (; shared_envs::Dict{name, EnvInfo},\n    envs_folder_path::String, \n    shared_env_names::Vector{String})\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.update_all-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.update_all","text":"updated all shared environments and the current project\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ShareAdd.update_all_envs-Tuple{}","page":"Internal functions and Index","title":"ShareAdd.update_all_envs","text":"updates all shared environments currently in LOAD_PATH\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#Index","page":"Internal functions and Index","title":"Index","text":"","category":"section"},{"location":"docstrings/","page":"Internal functions and Index","title":"Internal functions and Index","text":"","category":"page"}]
}
