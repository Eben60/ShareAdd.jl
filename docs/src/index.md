[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://eben60.github.io/ShareAdd.jl/) 
[![Build Status](https://github.com/Eben60/YAArguParser.jl/workflows/CI/badge.svg)](https://github.com/Eben60/YAArguParser.jl/actions?query=workflow%3ACI) 
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


# ShareAdd.jl

This Julia package is intended for interactive use. It exports the macro `@usingany`: This macro makes package(s) available, if they are not already, and loads them with `using` keyword.

- If a package is available in an environment in LOAD_PATH, that's OK.
- If a package is available in a shared environment, this environment will be pushed into LOAD_PATH.
- Otherwise if it can be installed, you will be prompted to select an environment to install the package(s).
- If the package is not listed in any registry, an error will be thrown. 

The package also exports several utility functions - see the [Exported functions](@ref) section.

## Usage example

While working on your package `MyPackage` you may temporarily need packages `TOML`, `Plots`, and `Chairmarks`, which however you don't want to add to your package dependencies. You also need `Unitful`, which is already an installed dependence of `MyPackage`. `TOML` is available in the `stdlib`, `Plots` you already put into a shared environment `@utilities`, and `Chairmarks` is not on your computer yet. 

First, you add ShareAdd to your "main" (standard) enviroment, making it available at all times:

```
]
(YourEnv) pkg> activate 
  Activating project at `~/.julia/environments/v1.10`

(@v1.10) pkg> add ShareAdd
(...)
(@v1.10) pkg> activate . # back to your environment
(YourEnv) pkg> 
```

By that occasion you may also want to clean your standard environment: It is generally not recommended having a lot of packages there.

Now, the only thing you need, is to type into REPL (or adding to your script) the following two lines:

```
using ShareAdd
@usingany Unitful, TOML, Plots, Chairmarks
```

As `Chairmarks` was not installed yet, you will be asked as to where to install it. You may e.g. add it to your existing `@utilities` shared environment, or let create a new environment `@Chairmarks` and put it there. 

Afrerwards `@utilities` (and `@Chairmarks`, if created) will be added to `LOAD_PATH`, making their packages available.

Finally, the macro executes `using Unitful, TOML, Plots, Chairmarks` - and that's it. Enjoy!

## Likes & dislikes?

Star on GitHub, open an issue, contact me on Julia Discourse.

## Credits

Some code and inspiration from [EnvironmentMigrators.jl](https://github.com/mkitti/EnvironmentMigrators.jl) by Mark Kittisopikul. 

The AI from [Codeium](https://codeium.com/) helped me and bugged me (pun intended).

## Copyright and License

© 2024 Eben60

MIT License (see separate file `LICENSE`)

