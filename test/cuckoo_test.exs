defmodule CuckooTest do
  use ExUnit.Case

  test "create new cuckoo filter" do
    cf = Cuckoo.new(100, 16)
    struct = %Cuckoo.Filter{
               buckets: {:array, 32, 0, {:array, 4, 0, 0, 10}, 100},
               fingerprint_size: 16,
               fingerprints_per_bucket: 4,
               max_num_keys: 100
           }
    assert cf == struct
  end
end
