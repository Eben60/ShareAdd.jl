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
    isnothing(p) && (p = parse_packages(x))
  
    isnothing(p) && (println(err_msg); return nothing)
    (; packages, expr) = p


    @show packages, expr

    return nothing

end

export @shargs
