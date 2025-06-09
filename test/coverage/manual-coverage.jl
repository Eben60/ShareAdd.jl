@usingany Pkg
Pkg.test("ShareAdd"; coverage=true)

@usingany Coverage
srcfolder = normpath(@__DIR__, "../../src")
coverage = process_folder(srcfolder)

open("lcov.info", "w") do io
    LCOV.write(io, coverage)
end;

# clean_folder(".")