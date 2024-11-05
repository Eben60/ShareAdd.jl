# macro shargs(args...)
#     @show args
#     a = args[1]
#     @show a, typeof(a), propertynames(a), a.head, a.args
#     if a isa Expr && a.head == :call && a.args[1] == :(:) && length(a.args) >= 3
#         println("ok")
#     else
#         println("not ok")
#     end
#     println(a.args)
#     return nothing
# end

macro shargs(x)
    err_msg = """
    Cannot make sense of `@usingany` arguments. 
    If the error was NOT caused by a typo, and you believe you wrote a sensible syntax,
    please check the docs of `@usingany` and `make_importable` """

    p = parse_using_functions(x)
    if !isnothing(p)
        (; packages, expr) = p
    else
        p = parse_packages(x)
        isnothing(p) && (println(err_msg); return nothing)
        (; packages, expr) = p
    end

    @show packages, expr

    return nothing

end

export @shargs

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

export @shargs

function parse_colon(x)
    x isa Expr || return nothing
    (x.head == :call && x.args[1] == :(:) && length(x.args) == 3) || return nothing
    pkg = String(x.args[2])
    fns = [x.args[3] |> String]
    return (; pkg, fns)
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
        functions = x.args[2:end] .|> String
        return call_using_functions(pc, functions)
    else
        return nothing
    end
end


