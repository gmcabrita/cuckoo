defmodule CuckooTest do
  use ExUnit.Case

  test "create cuckoo filter and insert element" do
    {:ok, cf} = Cuckoo.new(100, 16) |> Cuckoo.insert("hello")
    assert Cuckoo.contains?(cf, "hello")
  end
end
