## Macros

```@autodocs
Modules = [ShareAdd]
Order   = [:macro, ]
```

## Types

All types are declared as `public`

```@autodocs
Modules = [ShareAdd]
Order   = [:type, ]
```

## Functions

### Exported functions

```@autodocs
Modules = [ShareAdd]
Order   = [:function]
Filter = t -> Base.isexported(ShareAdd, Symbol(t))
```

### Public functions

```@autodocs
Modules = [ShareAdd]
Order   = [:function]
Filter = t -> (! Base.isexported(ShareAdd, Symbol(t)) && Base.ispublic(ShareAdd, Symbol(t)))
```

### Internal functions

```@autodocs
Modules = [ShareAdd]
Order   = [:function]
Filter = t -> ! Base.ispublic(ShareAdd, Symbol(t))
```

## Index

```@index
```