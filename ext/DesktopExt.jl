module DesktopExt

using Desktop: open_file
using ShareAdd
import ShareAdd: showenv

function showenv(item)
    dep_path = first(DEPOT_PATH)
    isdir(dep_path) || error("$(dep_path) folder doesn't exist.")
    envs_folder = joinpath(dep_path, "environments")
    
    if isempty(item)
        if isdir(envs_folder) 
            open_file(envs_folder)
            return nothing
        else
            @warn "The environments folder doesn't exist. Opening the Julia depot folder instead."
            open_file(dep_path)
        end
    end

    if item == "stdlib"
        path = Sys.STDLIB
    else
        path = joinpath(envs_folder, item)
    end

    if isdir(path)
        open_file(path)
        return nothing
    else
        (; envs) = ShareAdd.info(item; std_lib=true, disp_rslt=false, ret_rslt=true)
        isempty(envs) && error("Package $item is not found in any shared environment, no a shared env of that name exists")
        for env in envs
            @show env
            showenv(env)
        end
    end

    return nothing
end

end # module