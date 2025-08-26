"""
    Module AbortableTerminalMenu

Documentation at https://github.com/Eben60/AbortableTerminalMenu.jl 
"""
module AbortableTerminalMenu
using REPL
# using REPL.TerminalMenus
using REPL.TerminalMenus: MultiSelectMenu, MultiSelectConfig, AbstractConfig, Config

include("request.jl")
include("MultiSelectMenu.jl")

# export AbortableMultiSelectMenu
export request 

end
