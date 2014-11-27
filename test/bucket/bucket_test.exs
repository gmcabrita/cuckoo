defmodule Cuckoo.BucketTest do
  use ExUnit.Case

  test "create new bucket" do
    assert Cuckoo.Bucket.new(4) == {:array, 4, 0, 0, 10}
  end
end
