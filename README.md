Cuckoo
======

[![Build Status](https://img.shields.io/github/workflow/status/gmcabrita/cuckoo/CI/master.svg)](https://github.com/gmcabrita/cuckoo/actions)
[![Coverage Status](https://img.shields.io/coveralls/gmcabrita/cuckoo.svg?style=flat)](https://coveralls.io/r/gmcabrita/cuckoo?branch=master)
[![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/cuckoo)
[![Hex Version](http://img.shields.io/hexpm/v/cuckoo.svg?style=flat)](https://hex.pm/packages/cuckoo)
[![License](http://img.shields.io/hexpm/l/cuckoo.svg?style=flat)](https://github.com/gmcabrita/cuckoo/blob/master/LICENSE)

Cuckoo is a pure Elixir implementation of a [Cuckoo Filter](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf).

# Usage

Add Cuckoo as a dependency in your mix.exs file.

```elixir
def deps do
  [{:cuckoo, "~> 1.0"}]
end
```

# Examples

```iex
iex> cf = Cuckoo.new(1000, 16, 4)
%Cuckoo{...}

iex> {:ok, cf} = Cuckoo.insert(cf, 5)
%Cuckoo{...}

iex> Cuckoo.contains?(cf, 5)
true

iex> {:ok, cf} = Cuckoo.delete(cf, 5)
%Cuckoo{...}

iex> Cuckoo.contains?(cf, 5)
false
```

# Implementation Details

The implementation follows the specification as per the paper above.

For hashing we use the x64_128 variant of Murmur3 and the Erlang phash2.
