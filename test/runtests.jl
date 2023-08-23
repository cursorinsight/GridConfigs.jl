###-----------------------------------------------------------------------------
### Copyright (C) The GridConfigs contributors
###
### SPDX-License-Identifier: MIT
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

using Test

using Aqua: test_all as aqua
using Base: product
using GridConfigs: GridConfig, as_namedtuple, unfold

##------------------------------------------------------------------------------
## supported formats
##------------------------------------------------------------------------------

import JSON, TOML, YAML

###=============================================================================
### Tests
###=============================================================================

@testset "Aqua            " begin
    using GridConfigs
    aqua(GridConfigs; project_toml_formatting = (VERSION >= v"1.7"))
end

@testset "GridConfig()    " begin
    config = GridConfig()
    @test config isa GridConfig
    @test isempty(config)
    @test length(config) == 0
    @test collect(keys(config)) == []
    @test collect(values(config)) == []
end

@testset "GridConfig: $format" for format in [JSON, TOML, YAML]
    config = GridConfig("test.$(lowercase(string(format)))", format)
    @test config isa GridConfig

    # getindex
    @test all(config[p] isa GridConfig
              for p in ["a", "b", "c", "c.x", "c.y", "d"])
    @test config["a.x"] == 1
    @test config["a.y"] == 2.0
    @test config["a.z"] === nothing
    @test config["b.foo"] == "foo"
    @test config["b.bar"] == true
    @test config["c.x.one"] == [1, 2, 3]
    @test config["c.y.i"] == 1.0
    @test config["d.baz"] == ["alpha", "bravo"]

    @test config["a.x", default = "x"] == 1
    @test config["a.z", default = "z"] == "z"

    # setindex
    config["a.x"] += 1
    @test config["a.x"] == 2

    # haskey
    @test haskey(config, "a.x")
    @test haskey(config, "c.x.one")

    # keys
    @test length(keys(config)) == 9
    @test keys(config["a"]) == ["x", "y"]
    @test keys(config["c"]) == ["x.one", "x.two", "y.i", "y.j"]
    @test keys(config, "a") == ["a.x", "a.y"]
    @test keys(config, "c") == ["c.x.one", "c.x.two", "c.y.i", "c.y.j"]
    @test keys(config, "c.x") == ["c.x.one", "c.x.two"]

    # values
    @test length(values(config)) == 9
    @test collect(values(config["a"])) == [2, 2.0]
    @test collect(values(config["c"])) == [[1, 2, 3], [4, 5, 6], 1.0, 2.0]

    # pairs
    @test length(pairs(config)) == 9
    @test collect(pairs(config["a"])) == ["x" => 2, "y" => 2.0]
    @test collect(pairs(config, "b")) == ["b.bar" => true, "b.foo" => "foo"]

    # length & iterate
    @test length(config) == 9
    @test !isempty(config)
    @test collect(config["a"]) == ["x" => 2, "y" => 2.0]
    @test collect(config["b"]) == ["bar" => true, "foo" => "foo"]

    # getproperty
    @test all(g isa GridConfig for g in [config.a, config.b, config.c])
    @test config.a.y == 2.0
    @test config.a.w === nothing
    @test config.b.foo == "foo"
    @test config.c.x.two == [4, 5, 6]

    # setproperty!
    config.a.y -= 1
    @test config.a.y == 1.0

    # hasproperty
    @test all(hasproperty(config, p) for p in [:a, :b, :c, :d])

    # propertynames
    @test propertynames(config) == [:a, :b, :c, :d]

    # as_namedtuple
    @test as_namedtuple(config.a) == (x = 2, y = 1.0)

    # unfold
    @test unfold(config) == [config]
    @test unfold(config, "a.x") == [config]
    let configs = unfold(config, "c.x.one")
        @test length(configs) == 3
        @test all(cfg.a.x == 2 && cfg.b.foo == "foo" for cfg in configs)
        @test all(cfg.c.x.one == i for (i, cfg) in enumerate(configs))
    end
    let configs = unfold(config, "c.x.one", "c.x.two")
        @test length(configs) == 9
        @test all(cfg.a.x == 2 && cfg.b.foo == "foo" for cfg in configs)
        @test all(cfg.c.x.one == one && cfg.c.x.two == two
                  for ((two, one), cfg) in zip(product(4:6, 1:3), configs))
        @test configs == unfold(config, "c.x")
    end
    @test length(unfold(config, :)) == 18
    @test length(unfold(config, "c")) == 9
    @test length(unfold(config, "d")) == 2
end
