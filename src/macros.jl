"""
    @usingany pkg
    @usingany pkg1, pkg2, ... 
    @usingany pkg: fn
    @usingany pkg: fn, @mcr, ... 

Makes package(s) available, if they are not already, and loads them with `using` keyword. 

- If a package is available in an environment in `LOAD_PATH`, that's OK.
- If a package is available in a shared environment, this environment will be pushed into `LOAD_PATH`.
- Otherwise if package(s) can be installed, you will be prompted to select an environment to install each package.
- If the package is not listed in any registry, an error will be thrown.

This macro is exported.
"""
macro usingany(args...)
    (;kwargs, last_kwarg_index) = parse_kwargs(args)
    lastargs = length(args) - last_kwarg_index
    lastargs > 1 && error(err_msg)

    p = lastargs == 0 ? nothing : parse_usings(args[end])
    (; packages, expr) = p

    mi = make_importable(packages)
    mi != :success && error("Some packages could not be installed")

    update_if_asked(kwargs, packages)

    q = Meta.parse(expr)
    return q
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

function parse_packages(x)
    if x isa Symbol
        x = [x]
    else
        if x isa Expr && x.head == :tuple
            x = x.args
        else
            return nothing
        end
    end

    x = String.(x)
    pkglist = join(x, ", ")
    expr = "using $(pkglist)"
    return (; packages=x, expr)
end

function parse_colon(x)
    x isa Expr || return nothing
    (x.head == :call && x.args[1] == :(:) && length(x.args) == 3) || return nothing
    pkg = String(x.args[2])
    fns = fn2string(x.args[3]) 
    fns = [fns |> String]
    return (; pkg, fns)
end

"converts function or macro name to string"
function fn2string(x)
    x isa Symbol && return x |> String
    x isa Expr || error("problems making up sense of arguments")
    x.head == :macrocall || error("problems making up sense of arguments")
    return x.args[1] |> String
end

function call_using_functions(args...)
    (; pkg, fns) = merge_fns2call(args...)

    packages = pkg
    expr = "using $(pkg): $(join(fns, ", "))"
    return (; packages, expr)
end

merge_fns2call(x) = x

function merge_fns2call(nt, fs)
    (; pkg, fns) = nt
    append!(fns, fs)
    return (; pkg, fns)
end

function parse_using_functions(x)
    x isa Expr || return nothing
    pc = parse_colon(x)
    isnothing(pc) || return call_using_functions(pc)

    if x.head == :tuple
        x1 = x.args[1]
        pc = parse_colon(x1)
        isnothing(pc) && return nothing
        functions = x.args[2:end] .|> fn2string
        return call_using_functions(pc, functions)
    else
        return nothing
    end
end


function parse_kwarg(arg)
    arg isa Expr || return nothing
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