macro prs(args...)

    (;kwargs, last_kwarg_index) = parse_kwargs(args)

    lastargs = length(args) - last_kwarg_index

    lastargs > 1 && error(err_msg)

    p = lastargs == 0 ? nothing : parse_usings(args[end])
    (; packages, expr) = p

    update_if_asked(kwargs, packages)

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


macro usingtmp()
    activate_temp()
end

macro usingtmp(arg)


    p = parse_usings(arg)
    (; packages, expr) = p

    activate_temp()
    Pkg.add(packages)

    # return nothing

    q = Meta.parse(expr)
    return q
end

export @usingtmp