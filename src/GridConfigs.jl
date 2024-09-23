###-----------------------------------------------------------------------------
### Copyright (C) The GridConfigs contributors
###
### SPDX-License-Identifier: MIT
###-----------------------------------------------------------------------------

module GridConfigs

###=============================================================================
### Exports
###=============================================================================

export GridConfig, as_dict, as_namedtuple, unfold

###=============================================================================
### Imports
###=============================================================================

using PackageExtensionCompat: @require_extensions

import Base: getindex, haskey, setindex!
import Base: keys, pairs, values
import Base: getproperty, hasproperty, propertynames, setproperty!
import Base: ==, hash, iterate, length, show
import Base: empty, filter

###=============================================================================
### Implementation
###=============================================================================

"""
A hierarchical configuration using string keys, with benefits:

Indexing:
* indexable with dot separated hierarchical keys (e.g., "group.key");
* default value can be passed to indexing with `default = <value>`;
* if key does not exist, returns default value instead of throwing `KeyError`;
* default value defaults to `nothing`.

Property access:
* groups and keys can be accessed via properties (e.g., `config.group.key`);
* read/write support.

Unfolding: any combination of keys can be unfolded, see documentation of
[`unfold`](@ref).
"""
struct GridConfig
    cfg::Dict{String, Any}
end

GridConfig() = GridConfig(Dict())

"""
Load a `GridConfig` from a stream or a file, using `mod`ule as a format
interpreter.

Supported formats: JSON, TOML, YAML, provided that the corresponding Julia
library is loaded.
"""
function GridConfig(input, mod::Module; kwargs...)
    return GridConfig(input, Val(nameof(mod)); kwargs...)
end

"""
Return the hierarchical configuration as a native `Dict`.
"""
as_dict(config::GridConfig)::Dict{String, Any} = getfield(config, :cfg)

"""
Return the hierarchical configuration as a `NamedTuple`.
"""
function as_namedtuple(config::GridConfig)::NamedTuple
    return NamedTuple(property => getproperty(config, property)
                      for property in propertynames(config))
end

function getindex(config::GridConfig, idx::AbstractString; default = nothing)
    try
        result = foldl(getindex, split(idx, '.'); init = as_dict(config))
        return result isa Dict{String, Any} ? GridConfig(result) : result
    catch ex
        return ex isa KeyError ? default : rethrow()
    end
end

function setindex!(config::GridConfig, value, idx::AbstractString)
    (last, reversed_front...) = reverse(split(idx, '.'))
    subconfig = foldr(reversed_front; init = as_dict(config)) do key, subconfig
        return get!(subconfig, key, Dict{String, Any}())
    end
    return subconfig[last] = value
end

struct MissingMarker end

function haskey(config::GridConfig, key::AbstractString)::Bool
    config[key, default = MissingMarker()] !== MissingMarker()
end

function keys(config::GridConfig)::Vector{String}
    all_keys = map(collect(keys(as_dict(config)))) do key
        value = config[key]
        return value isa GridConfig ? "$key." .* keys(value) : [key]
    end
    return sort!(vcat(all_keys...))
end

function keys(config::GridConfig, key::AbstractString)::Vector{String}
    return "$key." .* keys(config[key])
end

function values(config::GridConfig)
    return (config[key] for key in keys(config))
end

function pairs(config::GridConfig)
    return (key => config[key] for key in keys(config))
end

function pairs(config::GridConfig, key::AbstractString)
    return (subkey => config[subkey] for subkey in keys(config, key))
end

function getproperty(config::GridConfig, name::Symbol)
    return config[String(name)]
end

function setproperty!(config::GridConfig, name::Symbol, value)
    return config[String(name)] = value
end

function hasproperty(config::GridConfig, name::Symbol)::Bool
    return haskey(config, String(name))
end

function propertynames(config::GridConfig)::Vector{Symbol}
    return sort!(Symbol.(keys(as_dict(config))))
end

function ==(a::GridConfig, b::GridConfig)::Bool
    return as_dict(a) == as_dict(b)
end

function hash(a::GridConfig, h::UInt)::UInt
    return hash(as_dict(a), hash(:GridConfig, h))
end

iterate(config::GridConfig, state = 1) = iterate(pairs(config), state)

length(config::GridConfig)::Int = length(keys(config))

function show(io::IO, config::GridConfig)
    subio = IOContext(io, :compact => true)
    print(io, "GridConfig")
    all_pairs = collect(config)
    if isempty(all_pairs)
        print(io, "()")
    else
        limit = get(io, :limit, false)::Bool
        n = length(all_pairs)
        w = all_pairs .|> first .|> length |> maximum
        print(io, " with $n entr$(n == 1 ? "y" : "ies"):")
        for (n, (k, v)) in enumerate(all_pairs)
            print(subio, "\n  $(rpad(k, w)) = $(repr(v))")
            limit && n >= 10 && (print(io, "…"); break)
        end
    end
end

empty(::GridConfig) = GridConfig()

function filter(f, config::GridConfig)::GridConfig
    filtered = empty(config)
    for pair in config
        if f(pair)
            filtered[pair.first] = pair.second
        end
    end
    return filtered
end

"""
    unfold(config::GridConfig, keys::AbstractString...)::Vector{GridConfig}

Unfold a `config` instance at `keys`.

For every key `k` in `keys`, which has a vector value:
* create as many copies of `config` as many items the vector has;
* set the value of `k` in each copy to the corresponding item in the vector.

For every key `k` in `keys`, which has a subconfig:
* fully unfold the subconfig (using `unfold(subconfig, :)`);
* create as many copies of `config` as many instances the unfold produces;
* set the value of `k` in each copy to the corresponding unfolded subconfig.

When multiple keys are given, construct every possible combination.
"""
function unfold(config::GridConfig,
                key::AbstractString,
                rest::AbstractString...
               )::Vector{GridConfig}
    value = config[key]
    if value isa GridConfig
        value = as_dict.(unfold(value, :))
    end
    if value isa AbstractVector
        return mapreduce(append!, value) do item
            config_slice = deepcopy(config)
            config_slice[key] = item
            return unfold(config_slice, rest...)
        end
    else
        return unfold(config, rest...)
    end
end

unfold(config::GridConfig)::Vector{GridConfig} = [config]

"""
    unfold(config::GridConfig, ::Colon)::Vector{GridConfig}

Fully unfold a `config` instance at all keys (with vector values).
"""
unfold(config::GridConfig, ::Colon) = unfold(config, keys(config)...)

function __init__()
    @require_extensions
end

end # module GridConfigs
