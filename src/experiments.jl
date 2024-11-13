# @

@kwdef mutable struct accepted_kwargs
    update_pkg::Bool = false
    update_env::Bool = false
    update_all::Bool = false
end


function parse_kwarg(arg)
    arg isa Expr || return nothing
    @show arg.head #, arg.head == :(=)
    arg.head == :(=) || return nothing

    kw = arg.args[1]
    val = arg.args[2]
    val isa Bool || error("Expected a boolean value for $kw")
    return (; kw, val)
end

function parse_kwargs(args)
    i = 0
    kwargs = accepted_kwargs()
    for arg in args
        pk = parse_kwarg(arg)
        isnothing(pk) && break
        (; kw, val) = pk
        kw = Symbol(kw)
        hasproperty(kwargs, kw) || error("Unknown keyword $kw")
        setproperty!(kwargs, kw, val)
        i += 1
    end
    return (;kwargs, last_kwarg_index=i)
end


macro prs(args...)
    err_msg = """
    Cannot make sense of `@usingany` arguments. 
    If the error was NOT caused by a typo, and you believe you wrote a sensible syntax,
    please check the docs of `@usingany` and `make_importable` """

    (;kwargs, last_kwarg_index) = parse_kwargs(args)

    lastargs = length(args) - last_kwarg_index

    lastargs > 1 && error(err_msg)

    p = lastargs == 0 ? nothing : parse_usings(args[end])

    @show p, lastargs, kwargs
    return nothing
end



export @prs

macro dsp(x)
    # @show x.head, x.args, x.args[3], typeof(x.args[3])
    xx = x.args[3]
    @show xx.head, xx.args
    return nothing
end

"""
julia> @dsp Foo: @bar
(xx.head, xx.args) = (:macrocall, Any[Symbol("@bar"), :(#= REPL[9]:1 =#)])
"""

export @dsp