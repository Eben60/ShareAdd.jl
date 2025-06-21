## Changelog

### Release 2.3.0

_2025-06-22_ 

- Added [`ShareAdd.tidyup`](@ref) function for cleaning up cluttered shared environments.
- Added docs section on [Installation and First Steps](@ref "Installation and first steps").
- Warnings, docs and workaround tips for an [issue](@ref "Note for Julia v1.12 in VSCode"), which may occur with Julia v1.12 in VSCode.
- Some fixes and refactoring.

### Release 2.2.0

_2025-05-19_ 

#### Semi-breaking change

- Changed the default (i.e. without kwargs) behavior [`ShareAdd.delete(nm)`](@ref) or equivalently the behavior of [`ShareAdd.delete(nm; inall=false, force=false)`](@ref). Now, instead of skipping the deletion if a package is in multiple shared environments, or if env is in the `LOAD_PATH`, the function will open a user dialog. Futhermore, the kwargs now take triple-valued (force/ask/skip) arguments, for details see the docs. As the function is mostly expected to be called interactively, and behavior change, if relevant, will be obvious and self-explaining, the change was considered not "breaking enough" to warrant a new major version.

#### New feature

- Added [`@showenv`](@ref) macro, which allows to open the environment folder in your desktop file manager.

### Release 2.1.1

_2025-04-28_ 

- Some fixes and refactoring, esp. of the test suite.

### Release 2.1.0

_2025-01-24_ 

- Added a method for [`ShareAdd.update()`](@ref) and [`ShareAdd.delete()`](@ref) in form `delete("@Foo" => "bar")`
- Set the lower bound for version-specific manifests now to Julia v1.10.8 (as the feature was backported in Julia)

### Release 2.0.3 & 2.0.4

_2025-01-19_ , _2025-01-21_

- Substantially extended tests coverage. 
- Fixed a minor bug or two.

### Releases 2.0.1 & 2.0.2

_2025-01-18_ 

#### Fixes

- Workaround for an issue that sometimes occured when running the test suite on a CI server. 
- Fix a bug with [`ShareAdd.update()`](@ref) call without arguments.

### Release 2.0.0

_2025-01-18_ 

#### Summary

The utilities for managing environments were completely revamped.

#### Breaking changes

- No functions are exported any more, only the both macros [`@usingany`](@ref) and [`@usingtmp`](@ref) are exported.
- A number of functions were made internal instead of exported/public or changed names or usage.

#### New features

- New or renamed public functions with short and easy to note names [`info`](@ref ShareAdd.info), [`update`](@ref ShareAdd.update), [`delete`](@ref ShareAdd.delete), and [`reset`](@ref ShareAdd.reset) provide extended functionalities for managing shared environments.
- Support for version-specific manifests.

#### Other changes

- This documentation was somewhat restructured.

### Releases 0.1.1 .. 1.0.4

Work in progress 😓

### Initial release  0.1.0

_2024-10-13_


## Likes & dislikes?

Star on [GitHub](https://github.com/Eben60/ShareAdd.jl), open an issue, contact [me](https://discourse.julialang.org/u/eben60/summary) on Julia Discourse.

## Credits

Some code and inspiration from [EnvironmentMigrators.jl](https://github.com/mkitti/EnvironmentMigrators.jl) by Mark Kittisopikul. 

The AI from [Codeium](https://codeium.com/) helped me and bugged me (pun intended).

## Copyright and License

© 2024, 2025 Eben60

MIT License (see separate file `LICENSE`)
