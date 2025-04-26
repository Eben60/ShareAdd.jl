using Test
using ShareAdd
using ShareAdd: is_in_registries

@test is_in_registries("Unitful")
@test ! is_in_registries("NO_Ssuch_NOnssensse")   