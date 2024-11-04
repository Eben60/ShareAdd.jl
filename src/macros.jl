"""
    @usingany pkg
    @usingany pkg1, pkg2, ... 

Makes package(s) available, if they are not already, and loads them with `using` keyword. 

- If a package is available in an environment in `LOAD_PATH`, that's OK.
- If a package is available in a shared environment, this environment will be pushed into `LOAD_PATH`.
- Otherwise if it can be installed, you will be prompted to select an environment to install the package(s).
- If the package is not listed in any registry, an error will be thrown.

This macro is exported.
"""
macro usingany(packages)

    if packages isa Symbol
        packages = [packages]
    else
        if packages isa Expr && packages.head == :tuple
            packages = packages.args
        else
            error("The input should be either package name or multiple package names separated by commas")
        end
    end

    packages = String.(packages)

    mi = make_importable(packages)
    mi != :success && error("Some packages could not be installed")

    pkglist = join(packages, ", ")

    q = Meta.parse("using $(pkglist)")

    return q
end
