include("makedocs.jl")
;

# deployment done on the server anyway
# don't normally run deploydocs here
deploydocs(
    repo = "github.com/Eben60/YAArguParser.jl.git",
    versions = nothing,
    push_preview = true
)
