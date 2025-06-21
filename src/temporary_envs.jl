function is_temporary_env()
    p = Base.active_project() |> abspath
    temporarydir = (tempdir() |> abspath)
    return startswith(p, temporarydir)
end
export is_temporary_env

function is_package(projectpath)
    isfile(projectpath) || return false
    p = TOML.parsefile(projectpath)
    return haskey(p, "name")
end

is_package() = is_package(Base.active_project())
export is_package

"""
    activate_temp()

If current environment is a temporary one, does nothing. Otherwise activates a temporary environment. 
If the initial environment was a package (under development), 
makes this package available in the new environment by calling `Pkg.develop`.

Returns `nothing`.
"""
function activate_temp()
    is_temporary_env() && return nothing
    ispkg = is_package()

    if ispkg
        pr = Base.active_project() |> dirname
    end
    Pkg.activate(temp=true)
    ispkg && Pkg.develop(path=pr)

    return nothing
end