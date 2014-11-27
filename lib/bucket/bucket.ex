defmodule Cuckoo.Bucket do
  @moduledoc """
  This module implements a Bucket.
  """

  @type t :: Array.t

  @doc """
  Creates a new bucket with the given size `n`.
  """
  @spec new(pos_integer) :: t
  def new(n) do
    Array.new([n, :fixed])
  end

  @doc """
  Sets the entry `index` to `element`.

  Returns the updated bucket.
  """
  @spec set(t, non_neg_integer, pos_integer) :: t
  def set(bucket, index, element) do
    Array.set(bucket, index, element)
  end

  @doc """
  Returns the element at the specified `index`.
  """
  @spec get(t, non_neg_integer) :: pos_integer
  def get(bucket, index) do
    Array.get(bucket, index)
  end


  @doc """
  Checks if the `bucket` has any room left.

  Returns `{ :ok, index }` if it finds an empty entry in the bucket,
  otherwise returns `{ :err, :full }`.
  """
  @spec has_room?(t) :: { :ok, pos_integer } | { :err, :full }
  def has_room?(bucket) do
    index = Enum.find_index(bucket, fn (x) -> x == nil end)
    unless index do
      { :err, :full }
    else
      { :ok, index }
    end
  end

  @doc """
  Returns `true` if the bucket contains the `element`, otherwise returns `false`.

  Alternatively you can use `element in bucket` instead of calling this function.
  """
  @spec contains?(t, pos_integer) :: boolean
  def contains?(bucket, element) do
    element in bucket
  end

end
