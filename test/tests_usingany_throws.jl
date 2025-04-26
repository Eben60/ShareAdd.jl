using ShareAdd: @usingany

@test_throws ArgumentError @macroexpand @usingany 
@test_throws ArgumentError @macroexpand @usingany update_pkg = true