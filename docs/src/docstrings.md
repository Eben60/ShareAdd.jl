## Macros

```@autodocs
Modules = [ShareAdd]
Order   = [:macro, ]
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

## Public types

```@autodocs
Modules = [ShareAdd]
Order   = [:type, ]
```

## Index

```@index
```