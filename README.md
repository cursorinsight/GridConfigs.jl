[![CI](https://github.com/cursorinsight/GridConfigs.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/cursorinsight/GridConfigs.jl/actions/workflows/CI.yml)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

# GridConfigs.jl

A hierarchical configuration using string keys, with benefits:

Indexing:
* indexable with dot separated hierarchical keys (e.g., "group.key");
* default value can be passed to indexing with `default = <value>`;
* if key does not exist, returns default value instead of throwing `KeyError`;
* default value defaults to `nothing`.

Property access:
* groups and keys can be accessed via properties (e.g., `config.group.key`);
* read/write support.

The library also supports unfolding via the `unfold` function, producing the
Cartesian combination of all list values, see details [below](#unfolding). Hence
the name `GridConfigs.jl` (i.e., a rectangular grid of configuration values).

## Loading

Assume you have a TOML configuration file called `config.toml`:

```toml
[a]
x = 1
y = 2.0

[b]
foo = "foo"
bar = true

[c.x]
one = [1, 2, 3]
two = [4, 5, 6]

[c.y]
i = 1.0
j = 2.0

[d]
baz = ["alpha", "bravo"]
```

You can parse this into a `GridConfig` using the following command:

```julia
julia> ]add https://github.com/cursorinsight/GridConfigs.jl

julia> using GridConfigs, TOML; config = GridConfig("config.toml", TOML)
GridConfig with 9 entries:
  a.x     = 1
  a.y     = 2.0
  b.bar   = true
  b.foo   = "foo"
  c.x.one = [1, 2, 3]
  c.x.two = [4, 5, 6]
  c.y.i   = 1.0
  c.y.j   = 2.0
  d.baz   = ["alpha", "bravo"]
```

## Reading

To access entries in the config, you can use either indexing with string keys or
using property access. Note:

* the use of hierarchical keys (e.g., "x.one");
* accessing a non-existent key returns `nothing`;

```julia
julia> config["a"]
GridConfig with 2 entries:
  x = 1
  y = 2.0

julia> config.a.x
1

julia> config.missing |> typeof
Nothing
```

You can also specify a default value to return instead of `nothing` for
non-existent keys (works with indexing syntax only):

```julia
julia> config["a.y", default="gotcha!"]
2.0

julia> config["missing", default="gotcha!"]
"gotcha!"
```

## Writing

Both indexing and property access can be used to update entries in the config:

```julia
julia> config["a.x"] += 3
4

julia> config.a.y += 1.5
3.5

julia> sum(values(config.a))
7.5
```

As demonstrated by the last call, `GridConfig` also supports the standard
`keys`, `values` and `pairs` functions:

```julia
julia> keys(config.a)
2-element Vector{String}:
 "x"
 "y"

julia> pairs(config["b"]) |> collect
2-element Vector{Pair{String}}:
 "bar" => true
 "foo" => "foo"
```

## Unfolding

List values can be unfolded: from a single config containing lists of values, a
list of configs containing scalar values can be produced:

```julia
julia> config.c
GridConfig with 4 entries:
  x.one = [1, 2, 3]
  x.two = [4, 5, 6]
  y.i   = 1.0
  y.j   = 2.0

julia> unfold(config.c, "x.one")
3-element Vector{GridConfig}:
 GridConfig with 4 entries:
  x.one = 1
  x.two = [4, 5, 6]
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 2
  x.two = [4, 5, 6]
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 3
  x.two = [4, 5, 6]
  y.i   = 1.0
  y.j   = 2.0
```

When multiple list values are unfolded in a single step, every possible
combination of the scalar values is produced:

```julia
julia> unfold(config.c, "x.one", "x.two")
9-element Vector{GridConfig}:
 GridConfig with 4 entries:
  x.one = 1
  x.two = 4
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 1
  x.two = 5
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 1
  x.two = 6
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 2
  x.two = 4
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 2
  x.two = 5
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 2
  x.two = 6
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 3
  x.two = 4
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 3
  x.two = 5
  y.i   = 1.0
  y.j   = 2.0
 GridConfig with 4 entries:
  x.one = 3
  x.two = 6
  y.i   = 1.0
  y.j   = 2.0
```

If you specify the name of a group, all list values within that group are
unfolded. If you specify colon (`:`), everything is unfolded:

```julia
julia> unfold(config.c, "x.one", "x.two") ==
       unfold(config.c, "x")              ==
       unfold(config.c, :)
true

julia> unfold(config, "c") |> length
9

julia unfold(config, :) |> length
18
```

## Multiple formats

In addition to TOML, `GridConfigs.jl` also supports YAML and JSON files. All you
have to do is import the appropriate library and pass the module in the second
argument of the `GridConfig` constructor:

```julia
julia> using GridConfig, JSON; json_config = GridConfig("config.json", JSON)

julia> using GridConfig, YAML; yaml_config = GridConfig("config.yml", YAML)
```
