using Test
using ShareAdd
using ShareAdd: reset

load_path = copy(Base.LOAD_PATH)
reset()
@test Base.LOAD_PATH == ["@", "@v#.#", "@stdlib"]
# restoring LOAD_PATH
empty!(Base.LOAD_PATH)
append!(Base.LOAD_PATH, load_path)