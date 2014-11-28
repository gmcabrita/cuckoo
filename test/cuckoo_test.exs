defmodule CuckooTest do
  use ExUnit.Case

  test "create cuckoo filter, insert element and verify its existance" do
    {:ok, cf} = Cuckoo.new(100, 16) |> Cuckoo.insert("hello")
    assert Cuckoo.contains?(cf, "hello")
  end

  test "occupancy and false positives" do
    total_inserts = 100000
    cf = Cuckoo.new(total_inserts, 16, 4)
    {cf, inserts} = Enum.reduce(
      1..total_inserts,
      {cf, 0},
      fn (x, {acc, inserts}) ->
        case Cuckoo.insert(acc, x) do
          {:ok, cf} -> {cf, inserts + 1}
          {:err, :full} -> assert false
        end
      end
    )

    assert inserts == total_inserts

    {insert_count, false_count} =
    Enum.reduce(
      1..total_inserts,
      {0, 0}, # {inserts, false_queries}
      fn(x, {i, f}) ->
        insert = Cuckoo.contains?(cf, x)
        query = Cuckoo.contains?(cf, x + total_inserts)

        {if(insert, do: i + 1, else: i), if(query, do: f + 1, else: f)}
      end
    )

    assert insert_count == total_inserts

    total_queries = total_inserts
    false_positive_rate = 100.0 * false_count / total_queries

    assert false_positive_rate <= 0.015
  end
end
