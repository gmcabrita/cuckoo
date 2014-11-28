defmodule Cuckoo.BucketTest do
  use ExUnit.Case, async: true

  setup do
    { :ok, bucket: Cuckoo.Bucket.new(4) }
  end

  test "create new bucket", %{bucket: bucket} do
    assert bucket == Array.new(4)
  end

  test "check if a bucket has room", %{bucket: bucket} do
    assert Cuckoo.Bucket.has_room?(bucket) == { :ok, 0 }
  end

  test "check if a bucket contains an element after inserting", %{bucket: bucket} do
    bucket = Cuckoo.Bucket.set(bucket, 0, 10)
    assert Cuckoo.Bucket.contains?(bucket, 10)
  end

  test "get element from the bucket after inserting", %{bucket: bucket} do
    bucket = Cuckoo.Bucket.set(bucket, 0, 10)
    assert Cuckoo.Bucket.get(bucket, 0) == 10
  end
end
