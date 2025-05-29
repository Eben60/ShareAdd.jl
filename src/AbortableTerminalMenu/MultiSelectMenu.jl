
struct AbortableMultiConfig <: AbstractConfig
    config::Config
    checked::String
    unchecked::String
end

function AbortableMultiConfig(;
                           charset::Symbol = :ascii,
                           checked::String = "",
                           unchecked::String = "",
                           kwargs...)
    charset === :ascii || charset === :unicode || throw(ArgumentError("charset should be :ascii or :unicode, received $charset"))
    if isempty(checked)
        checked = charset === :ascii ? "[X]" : "✓"
    end
    if isempty(unchecked)
        unchecked = charset === :ascii ? "[ ]" : "⬚"
    end
    return AbortableMultiConfig(Config(; charset=charset, kwargs...), checked, unchecked)
end


function REPL.TerminalMenus.MultiSelectMenu(::AbortableMultiConfig, options::Array{String,1}; pagesize::Int=10, selected=Int[], warn::Bool=true, kwargs...)
    length(options) < 1 && error("MultiSelectMenu must have at least one option")

    # if pagesize is -1, use automatic paging
    pagesize = pagesize == -1 ? length(options) : pagesize
    # pagesize shouldn't be bigger than options
    pagesize = min(length(options), pagesize)
    # after other checks, pagesize must be at least 1
    pagesize < 1 && error("pagesize must be >= 1")

    pageoffset = 0
    _selected = Set{Int}()
    for item in selected
        push!(_selected, item)
    end
    MultiSelectMenu(options, pagesize, pageoffset, _selected, AbortableMultiConfig(; kwargs...))
end

function REPL.TerminalMenus.writeline(buf::IOBuffer, menu::MultiSelectMenu{AbortableMultiConfig}, idx::Int, iscursor::Bool)
    if idx in menu.selected
        print(buf, menu.config.checked, " ")
    else
        print(buf, menu.config.unchecked, " ")
    end

    print(buf, replace(menu.options[idx], "\n" => "\\n"))
end

REPL.TerminalMenus.cancel(m::MultiSelectMenu{AbortableMultiConfig}) = (m.selected = Set{Int64}([0]))


"""
    AbortableMultiSelectMenu(args...; kwargs) :: REPL.TerminalMenus.MultiSelectMenu{AbortableMultiConfig}

Based on and similar to `MultiSelectMenu` of `REPL.TerminalMenus`, with just one difference in behavior: 
Whereas `request(::MultiSelectMenu)` would return an empty `Set` both if cancelled and if no items were selected,
`request(::MultiSelectMenu{AbortableMultiConfig})` would return Set([0])) on cancel.
"""
AbortableMultiSelectMenu(options::Array{String,1}; pagesize::Int=10, selected=Int[], warn::Bool=true, kwargs...) =
    MultiSelectMenu(AbortableMultiConfig(), options; pagesize, selected, warn, kwargs...)
