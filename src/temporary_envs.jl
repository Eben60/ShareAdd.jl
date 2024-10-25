function is_temporary_env()
    p = Base.active_project() |> normpath
    temporarydir = (tempdir() |> normpath) * "/"
    return startswith(p, temporarydir)
end
export is_temporary_env