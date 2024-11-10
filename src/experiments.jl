# @

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
    kwargnames = [:update_pkg, :update_env, :update_all]

    i = 0
    kwargs = Dict(kwargnames .=> falses(length(kwargnames)))
    for arg in args
        pk = parse_kwarg(arg)
        isnothing(pk) && break
        (; kw, val) = pk
        haskey(kwargs, kw) || error("Unknown keyword $kw")
        kwargs[kw] = val
        i += 1
    end
    return (;kwargs=NamedTuple(kwargs), last_kwarg_index=i)
end

function parse_usings(x)
    err_msg = """
    Cannot make sense of `@usingany` arguments. 
    If the error was NOT caused by a typo, and you believe you wrote a sensible syntax,
    please check the docs of `@usingany` and `make_importable` """

    # usage like
    # @usingany Foo: bar
    p = parse_using_functions(x) 

    # usage like
    # @usingany Foo, Baz
    isnothing(p) && (p = parse_packages(x))
  
    isnothing(p) && error(err_msg)
    
    return p
end

macro prs(args...)
    err_msg = """
    Cannot make sense of `@usingany` arguments. 
    If the error was NOT caused by a typo, and you believe you wrote a sensible syntax,
    please check the docs of `@usingany` and `make_importable` """

    (;kwargs, last_kwarg_index) = parse_kwargs(args)
    # (; update_pkg, update_env, update_all) = kwargs

    lastargs = length(args) - last_kwarg_index

    lastargs > 1 && error(err_msg)

    p = lastargs == 0 ? nothing : parse_usings(args[end])

    @show p, lastargs, kwargs
    return nothing
end



export @prs