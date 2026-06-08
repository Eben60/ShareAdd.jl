
"""
    activate_here(source_file, packages)

Helper function for `@usinghere`. Checks if `packages` are available in the current LOAD_PATH.
If not, it activates the environment in the script's directory (or the parent directory if the script is in `src`),
and adds the missing packages.
"""
function activate_here(source_file, packages)
    file_path = string(source_file)
    if file_path == "none" || startswith(file_path, "REPL[") || isempty(file_path)
        error("`@usinghere` cannot be called from the REPL. It must be called from a script file.")
    end

    packages = packages isa AbstractString ? [packages] : collect(packages)

    cp = check_packages(packages)
    missing_pkgs = collect(setdiff(packages, cp.inpath_pkgs))

    if !isempty(missing_pkgs)
        dir = dirname(abspath(file_path))
        if basename(dir) == "src"
            target_dir = dirname(dir)
        else
            target_dir = dir
        end

        Pkg.activate(target_dir)
        Pkg.add(missing_pkgs)
    end
    return nothing
end
