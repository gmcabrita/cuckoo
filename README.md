Cuckoo [![Build Status](https://img.shields.io/travis/gmcabrita/cuckoo.svg?style=flat)](https://travis-ci.org/gmcabrita/cuckoo) [![Coverage Status](https://img.shields.io/coveralls/gmcabrita/cuckoo.svg?style=flat)](https://coveralls.io/r/gmcabrita/cuckoo?branch=master) [![License](http://img.shields.io/hexpm/l/cuckoo.svg?style=flat)](https://github.com/gmcabrita/cuckoo/blob/master/LICENSE) [![Hex Version](http://img.shields.io/hexpm/v/cuckoo.svg?style=flat)](https://hex.pm/packages/cuckoo)
======

Cuckoo is a pure Elixir implementation of a [Cuckoo Filter](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf).

# Usage

Add Cuckoo as a dependency in your mix.exs file.

```elixir
def deps do
  [{:cuckoo, "~> 0.1.0"}]
end
```

# Examples

```iex
iex> cf = Cuckoo.new(1000, 16, 4)
%Cuckoo.Filter{...}
iex> {:ok, cf} = Cuckoo.insert(cf, 5)
%Cuckoo.Filter{...}
iex> Cuckoo.contains?(cf, 5)
true
iex> {:ok, cf} = Cuckoo.delete(cf, 5)
%Cuckoo.Filter{...}
iex> Cuckoo.contains?(cf, 5)
false
```

# Implementation Details

The implementation follows the specification as per the paper above.

For hashing we use the x64_128 variant of Murmur3 and the Erlang phash2.
