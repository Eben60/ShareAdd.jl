using Documenter, ShareAdd

makedocs(
    modules = [ShareAdd],
    format = Documenter.HTML(; prettyurls = (get(ENV, "CI", nothing) == "true")),
    authors = "Eben60",
    sitename = "ShareAdd.jl",
    pages = Any[
        "General Info" => "index.md", 
        "Changelog, License etc." => "finally.md", 
        "Internal functions and Index" => "docstrings.md",
        ],
    checkdocs = :exports, 
    warnonly = [:missing_docs],
)
