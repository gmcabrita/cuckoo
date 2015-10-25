defmodule Cuckoo.Bucket do
  @moduledoc """
  This module implements a Bucket.
  """

  @type t :: :array.array()

  @doc """
  Creates a new bucket with the given size `n`.
  """
  @spec new(pos_integer) :: t
  def new(n) do
    :array.new([{:default, nil}, n, :fixed])
  end

  @doc """
  Sets the entry `index` to `element`.

  Returns the updated bucket.
  """
  @spec set(t, non_neg_integer, pos_integer) :: t
  def set(bucket, index, element) do
    :array.set(index, element, bucket)
  end

  @doc """
  Resets the entry `index` to the default value.

  Returns the updated bucket.
  """
  @spec reset(t, non_neg_integer) :: t
  def reset(bucket, index) do
    :array.reset(index, bucket)
  end


  @doc """
  Returns the element at the specified `index`.
  """
  @spec get(t, non_neg_integer) :: pos_integer
  def get(bucket, index) do
    :array.get(index, bucket)
  end


  @doc """
  Checks if the `bucket` has any room left.

  Returns `{ :ok, index }` if it finds an empty entry in the bucket,
  otherwise returns `{ :error, :full }`.
  """
  @spec has_room?(t) :: { :ok, pos_integer } | { :error, :full }
  def has_room?(bucket) do
    index = array_find(bucket, fn (x) -> x == nil end)

    if index do
      {:ok, index}
    else
      {:error, :full}
    end
  end

  @doc """
  Returns `true` if the bucket contains the `element`, otherwise returns `false`.
  """
  @spec contains?(t, pos_integer) :: boolean
  def contains?(bucket, element) do
    case find(bucket, element) do
      {:ok, _} -> true
      {:error, :inexistent} -> false
    end
  end

  @doc """
  Tries to find the given `element` in the `bucket`.

  Returns `{:ok, index}` if it finds it, otherwise returns `{:error, :inexistent}`.
  """
  @spec find(t, pos_integer) :: {:ok, non_neg_integer} | {:error, :inexistent}
  def find(bucket, element) do
    index = array_find(bucket, fn (x) -> x == element end)

    if index do
      {:ok, index}
    else
      {:error, :inexistent}
    end
  end

  @spec array_find(t, (any -> boolean)) :: nil | non_neg_integer
  defp array_find(array, fun) do
    size = :array.size(array)
    _array_find(array, size, size, fun)
  end

  @spec _array_find(t, non_neg_integer, non_neg_integer, (any -> boolean)) :: nil | non_neg_integer
  defp _array_find(_, _, 0, _), do: nil
  defp _array_find(array, size, left, fun) do
    index = size - left
    if fun.(:array.get(index, array)) do
      index
    else
      _array_find(array, size, left - 1, fun)
    end
  end

end
