"""
    Module AbortableTerminalMenu

Documentation at https://github.com/Eben60/AbortableTerminalMenu.jl 
"""
module AbortableTerminalMenu
using REPL
using REPL.TerminalMenus
using REPL.TerminalMenus: MultiSelectConfig, AbstractConfig, Config

include("MultiSelectMenu.jl")

# export AbortableMultiSelectMenu
# export request # re-export from REPL.TerminalMenus

end
