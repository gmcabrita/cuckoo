defmodule CuckooTest do
  use ExUnit.Case, async: true

  test "error message" do
    error = %Cuckoo.Error{reason: :reason, action: "test", element: :test_elem}
    assert Cuckoo.Error.message(error) == "could not test test_elem: reason"
  end

  test "create cuckoo filter, insert element and verify its existance" do
    {:ok, cf} = Cuckoo.new(100, 16) |> Cuckoo.insert("hello")
    assert Cuckoo.contains?(cf, "hello")
  end

  test "delete" do
    {:ok, cf} = Cuckoo.new(100, 16) |> Cuckoo.insert("hello")
    assert Cuckoo.contains?(cf, "hello")

    {:ok, cf} = Cuckoo.delete(cf, "hello")
    refute Cuckoo.contains?(cf, "hello")
  end

  test "sucessful insert!/2" do
    assert Cuckoo.new(4, 16)
           |> Cuckoo.insert!("hello")
           |> Cuckoo.contains?("hello")
  end

  test "unsucessful insert!/2" do
    assert_raise Cuckoo.Error, "could not insert element .: full", fn ->
      Cuckoo.new(3, 16)
      |> Cuckoo.insert!("hello")
      |> Cuckoo.insert!(",")
      |> Cuckoo.insert!("world")
      |> Cuckoo.insert!("!")
      |> Cuckoo.insert!(".")
      |> Cuckoo.insert!("/")
      |> Cuckoo.insert!("foo")
      |> Cuckoo.insert!("bar")
    end
  end

  test "successful delete!/2" do
    refute Cuckoo.new(3, 16)
           |> Cuckoo.insert!("hello")
           |> Cuckoo.delete!("hello")
           |> Cuckoo.contains?("hello")
  end

  test "unsucessful delete!/2" do
    assert_raise Cuckoo.Error, "could not delete element hello: inexistent", fn ->
      Cuckoo.new(3, 16)
      |> Cuckoo.delete!("hello")
    end
  end

  test "occupancy, false positives and removal" do
    total_inserts = 100_000
    cf = Cuckoo.new(total_inserts, 16, 4)

    {cf, inserts} =
      Enum.reduce(1..total_inserts, {cf, 0}, fn x, {acc, inserts} ->
        case Cuckoo.insert(acc, x) do
          {:ok, cf} -> {cf, inserts + 1}
          {:err, :full} -> assert false
        end
      end)

    assert inserts == total_inserts

    {insert_count, false_count} =
      Enum.reduce(
        1..total_inserts,
        # {inserts, false_queries}
        {0, 0},
        fn x, {i, f} ->
          insert = Cuckoo.contains?(cf, x)
          query = Cuckoo.contains?(cf, x + total_inserts)

          {if(insert, do: i + 1, else: i), if(query, do: f + 1, else: f)}
        end
      )

    assert insert_count == total_inserts

    total_queries = total_inserts
    false_positive_rate = 100.0 * false_count / total_queries

    assert false_positive_rate <= 0.015

    total_removes = div(total_inserts, 2)

    {cf, removal_count} =
      Enum.reduce(1..total_removes, {cf, 0}, fn x, {acc, removes} ->
        case Cuckoo.delete(acc, x) do
          {:ok, cf} -> {cf, removes + 1}
          {:err, :inexistent} -> assert false
        end
      end)

    assert removal_count == total_removes

    false_removal_count =
      Enum.reduce(1..total_removes, 0, fn x, i ->
        query = Cuckoo.contains?(cf, x)

        if query do
          i + 1
        else
          i
        end
      end)

    false_removal_rate = 100.0 * false_removal_count / total_removes
    assert false_removal_rate <= 0.01
  end
end
