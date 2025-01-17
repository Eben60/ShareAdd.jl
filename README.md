[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://eben60.github.io/ShareAdd.jl/) 
[![Build Status](https://github.com/Eben60/ShareAdd.jl/workflows/CI/badge.svg)](https://github.com/Eben60/ShareAdd.jl/actions?query=workflow%3ACI) 
[![Coverage](https://codecov.io/gh/Eben60/ShareAdd.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Eben60/ShareAdd.jl) 
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

# ShareAdd.jl

The aim of this Julia package is to help you to reduce clutter in your main shared environment (and thus avoid package incompatibility problems) by making it easy to use multiple shared or temporary environments. The package is primarily intended for interactive use. It exports two macros: `@usingany` and `@usingtmp`, envisioned for two different workflows. The package also provides several utility functions for managing shared environments.

## Documentation at 
[https://eben60.github.io/ShareAdd.jl/](https://eben60.github.io/ShareAdd.jl/)