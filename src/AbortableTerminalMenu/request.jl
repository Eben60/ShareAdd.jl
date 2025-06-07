function request(args...; kwargs...)
    @static if VersionNumber(VERSION.major, VERSION.minor) ≥ v"1.12"
        if isdefined(Main, :VSCodeServer)
            @warn ("The following dialog(s) will use REPL.TerminalMenus. Unfortunately those don't work well in VSCode under Julia v1.12. " *
            "You may try your luck, or abort using Ctrl/C . " * 
            "A working way to install package(s) into a shared env would be to execute the ShareAdd macro/function from Terminal " * 
            """or run your script from Terminal, or execute VSCode command "Julia: Run File in New Process" once. """ *
            "After package installation, you can return to normal use of VSCode. " *
            "Sorry for the inconvenience. See ShareAdd documentation for details.") maxlog = 1
            @info "You were WARNED ! Please make sure you've read the long message above, which is a WARNING." maxlog = 1
        end
    end
    REPL.TerminalMenus.request(args...; kwargs...)
end