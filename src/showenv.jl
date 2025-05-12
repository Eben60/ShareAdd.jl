"actual function is in the DesktopExt extension"
showenv() = nothing

"""
    @showenv
    @showenv item 

Open (shared) environment folder in your desktop GUI. The utility of this macro is that it makes it easy to access these
folders in your OS, which might otherwise require some jumping through hoops, as these are located in the hidden folder ~/.julia/

This macro is exported.

# Examples
```julia-repl
julia> @showenv # called without arguments, opens the "environments" folder which contains all shared environments
julia> @showenv Revise # open the environment folder(s) which contain the Revise package
julia> @showenv "Revise" # both quoted and unquoted forms of the argument are OK provided arg is a single word
julia> @showenv Math # opens the folder of the shared env @Math
```
"""
macro showenv(item="")
    info = "The additional package Desktop.jl is needed to open a folder in your desktop GUI. \n" *
        "It is currently not installed. You will be prompted to install it in a shared folder. \n\n"

    (; installable_pkgs) = check_packages("Desktop")
    isempty(installable_pkgs) || @info info
    make_importable("Desktop")

    isnothing(item) || (item = string(item))
    expr = """using Desktop: open_file; showenv("$(item)") """
    q = Meta.parse(expr)
    return q
end

export @showenv