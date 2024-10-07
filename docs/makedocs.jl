using Documenter, ShareAdd

makedocs(
    modules = [ShareAdd],
    format = Documenter.HTML(; prettyurls = (get(ENV, "CI", nothing) == "true")),
    authors = "Eben60",
    sitename = "ShareAdd.jl",
    pages = Any[
        "Usage" => "index.md", 
        "Docstrings" => "docstrings.md"
        ],
    checkdocs = :exports, 
    warnonly = [:missing_docs],
)
