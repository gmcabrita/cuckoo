defmodule Cuckoo do
  @moduledoc """
  This module implements a [Cuckoo Filter](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf).

  ## Implementation Details

  The implementation follows the specification as per the paper above.

  For hashing we use the x64_128 variant of Murmur3 and the Erlang phash2.

  ## Examples

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

  """

  use Bitwise
  alias Cuckoo.Bucket, as: Bucket

  @max_kicks 500

  defstruct [
    :buckets,
    :fingerprint_size,
    :fingerprints_per_bucket,
    :max_num_keys
  ]

  @type t :: %Cuckoo{
          buckets: :array.array(),
          fingerprint_size: pos_integer,
          fingerprints_per_bucket: pos_integer,
          max_num_keys: pos_integer
        }

  defmodule Error do
    defexception reason: nil, action: "", element: nil

    def message(exception) do
      "could not #{exception.action} #{exception.element}: #{exception.reason}"
    end
  end

  @doc """
  Creates a new Cuckoo Filter using the given `max_num_keys`, `fingerprint_size` and
  `fingerprints_per_bucket`.

  The suggested values for the last two according to one of the publications should
  be `16` and `4` respectively, as it allows the Cuckoo Filter to achieve a sweet spot
  in space effiency and table occupancy.
  """
  @spec new(pos_integer, pos_integer, pos_integer) :: Cuckoo.t()
  def new(max_num_keys, fingerprint_size, fingerprints_per_bucket \\ 4) when max_num_keys > 2 do
    num_buckets = upper_power_2(max_num_keys / fingerprints_per_bucket)
    frac = max_num_keys / num_buckets / fingerprints_per_bucket

    %Cuckoo{
      buckets:
        :array.new([
          if frac > 0.96 do
            num_buckets <<< 1
          else
            num_buckets
          end,
          :fixed,
          {:default, Bucket.new(fingerprints_per_bucket)}
        ]),
      fingerprint_size: fingerprint_size,
      fingerprints_per_bucket: fingerprints_per_bucket,
      max_num_keys: max_num_keys
    }
  end

  @doc """
  Tries to insert `element` into the Cuckoo Filter.

  Returns `{:ok, filter}` if successful, otherwise returns `{:error, :full}` from which
  you should consider the Filter to be full.
  """
  @spec insert(Cuckoo.t(), any) :: {:ok, Cuckoo.t()} | {:error, :full}
  def insert(
        %Cuckoo{
          buckets: buckets,
          fingerprint_size: bits_per_item,
          fingerprints_per_bucket: fingerprints_per_bucket
        } = filter,
        element
      ) do
    num_buckets = :array.size(buckets)
    {fingerprint, i1} = fingerprint_and_index(element, num_buckets, bits_per_item)
    i2 = alt_index(i1, fingerprint, num_buckets)

    i1_bucket = :array.get(i1, buckets)

    case Bucket.has_room?(i1_bucket) do
      {:ok, index} ->
        {:ok,
         %{filter | buckets: :array.set(i1, Bucket.set(i1_bucket, index, fingerprint), buckets)}}

      {:error, :full} ->
        i2_bucket = :array.get(i2, buckets)

        case Bucket.has_room?(i2_bucket) do
          {:ok, index} ->
            {:ok,
             %{
               filter
               | buckets: :array.set(i2, Bucket.set(i2_bucket, index, fingerprint), buckets)
             }}

          {:error, :full} ->
            random_i = Enum.random([i1, i2])
            kickout(filter, random_i, fingerprint, fingerprints_per_bucket)
        end
    end
  end

  @doc """
  Checks if the Cuckoo Filter contains `element`.

  Returns `true` if does, otherwise returns `false`.
  """
  @spec contains?(Cuckoo.t(), any) :: boolean
  def contains?(%Cuckoo{buckets: buckets, fingerprint_size: bits_per_item}, element) do
    num_buckets = :array.size(buckets)
    {fingerprint, i1} = fingerprint_and_index(element, num_buckets, bits_per_item)

    if Bucket.contains?(:array.get(i1, buckets), fingerprint) do
      true
    else
      i2 = alt_index(i1, fingerprint, num_buckets)
      Bucket.contains?(:array.get(i2, buckets), fingerprint)
    end
  end

  @doc """
  Attempts to delete `element` from the Cuckoo Filter if it contains it.

  Returns `{:error, :inexistent}` if the element doesn't exist in the filter, otherwise
  returns `{:ok, filter}`.
  """
  @spec delete(Cuckoo.t(), any) :: {:ok, Cuckoo.t()} | {:error, :inexistent}
  def delete(%Cuckoo{buckets: buckets, fingerprint_size: bits_per_item} = filter, element) do
    num_buckets = :array.size(buckets)
    {fingerprint, i1} = fingerprint_and_index(element, num_buckets, bits_per_item)

    b1 = :array.get(i1, buckets)

    case Bucket.find(b1, fingerprint) do
      {:ok, index} ->
        updated_bucket = Bucket.reset(b1, index)
        {:ok, %{filter | buckets: :array.set(i1, updated_bucket, buckets)}}

      {:error, :inexistent} ->
        i2 = alt_index(i1, fingerprint, num_buckets)
        b2 = :array.get(i2, buckets)

        case Bucket.find(b2, fingerprint) do
          {:ok, index} ->
            updated_bucket = Bucket.reset(b2, index)
            {:ok, %{filter | buckets: :array.set(i2, updated_bucket, buckets)}}

          {:error, :inexistent} ->
            {:error, :inexistent}
        end
    end
  end

  @doc """
  Returns a filter with the inserted element or raises `Cuckoo.Error` if an error occurs.
  """
  @spec insert!(Cuckoo.t(), any) :: Cuckoo.t() | no_return
  def insert!(filter, element) do
    case insert(filter, element) do
      {:ok, filter} ->
        filter

      {:error, reason} ->
        raise Cuckoo.Error, reason: reason, action: "insert element", element: element
    end
  end

  @doc """
  Returns a filter with the removed element or raises `Cuckoo.Error` if an error occurs.
  """
  @spec delete!(Cuckoo.t(), any) :: Cuckoo.t() | no_return
  def delete!(filter, element) do
    case delete(filter, element) do
      {:ok, filter} ->
        filter

      {:error, reason} ->
        raise Cuckoo.Error, reason: reason, action: "delete element", element: element
    end
  end

  # private helper functions

  @spec kickout(Cuckoo.t(), non_neg_integer, pos_integer, pos_integer, pos_integer) ::
          {:ok, Cuckoo.t()} | {:error, :full}
  defp kickout(filter, index, fingerprint, fingerprints_per_bucket, current_kick \\ @max_kicks)
  defp kickout(_, _, _, _, 0), do: {:error, :full}

  defp kickout(
         %Cuckoo{buckets: buckets} = filter,
         index,
         fingerprint,
         fingerprints_per_bucket,
         current_kick
       ) do
    bucket = :array.get(index, buckets)

    # randomly select an entry from the bucket
    rand = :rand.uniform(fingerprints_per_bucket) - 1

    # withdraw its fingerprint
    old_fingerprint = Bucket.get(bucket, rand)

    # replace it
    bucket = Bucket.set(bucket, rand, fingerprint)
    buckets = :array.set(index, bucket, buckets)

    # find a place to put the old fingerprint
    fingerprint = old_fingerprint
    num_buckets = :array.size(buckets)
    index = alt_index(index, fingerprint, num_buckets)
    bucket = :array.get(index, buckets)

    case Bucket.has_room?(bucket) do
      {:ok, b_index} ->
        bucket = Bucket.set(bucket, b_index, fingerprint)
        buckets = :array.set(index, bucket, buckets)
        {:ok, %{filter | buckets: buckets}}

      {:error, :full} ->
        kickout(
          %{filter | buckets: buckets},
          index,
          fingerprint,
          fingerprints_per_bucket,
          current_kick - 1
        )
    end
  end

  @spec gen_index(pos_integer, pos_integer) :: non_neg_integer
  defp gen_index(hash, num_buckets) do
    rem(hash, num_buckets)
  end

  @spec fingerprint(pos_integer, pos_integer) :: pos_integer
  defp fingerprint(hash, bits_per_item) do
    hash &&& (1 <<< bits_per_item) - 1
  end

  # calculates the smallest power of 2 greater than or equal to n
  @spec upper_power_2(float) :: pos_integer
  defp upper_power_2(n) do
    2
    |> :math.pow(Float.ceil(log2(n)))
    |> trunc
  end

  @spec log2(float) :: float
  defp log2(n) do
    :math.log(n) / :math.log(2)
  end

  @spec hash1(any) :: pos_integer
  defp hash1(element), do: Murmur.hash_x64_128(element)

  @spec hash2(pos_integer) :: pos_integer
  defp hash2(fingerprint), do: :erlang.phash2(fingerprint)

  @spec fingerprint_and_index(any, pos_integer, pos_integer) :: {pos_integer, non_neg_integer}
  defp fingerprint_and_index(element, num_buckets, bits_per_item) do
    hash = hash1(element)
    fingerprint = fingerprint(hash, bits_per_item)
    index = gen_index(hash >>> 32, num_buckets)

    {fingerprint, index}
  end

  @spec alt_index(non_neg_integer, pos_integer, pos_integer) :: non_neg_integer
  defp alt_index(i1, fingerprint, num_buckets) do
    i1 ^^^ gen_index(hash2(fingerprint), num_buckets)
  end
end
