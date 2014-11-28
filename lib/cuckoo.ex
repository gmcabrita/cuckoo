defmodule Cuckoo do
  @moduledoc """
  This module implements a Cuckoo Filter.
  """

  use Bitwise
  alias Cuckoo.Bucket, as: Bucket

  @max_kicks 500

  defmodule Filter do
    defstruct [
            :buckets,
            :fingerprint_size,
            :fingerprints_per_bucket,
            :max_num_keys
        ]

    @type t ::
    %Filter{
            buckets: Array.t,
            fingerprint_size: pos_integer,
            fingerprints_per_bucket: pos_integer,
            max_num_keys: pos_integer
        }
  end

  @doc """
  Creates a new Cuckoo Filter using the given `max_num_keys`, `fingerprint_size` and
  `fingerprints_per_bucket`.

  The suggested values for the last two according to one of the publications should
  be `16` and `4` respectively, as it allows the Cuckoo Filter to achieve a sweet spot
  in space effiency and table occupancy.
  """
  @spec new(pos_integer, pos_integer, pos_integer) :: Filter.t
  def new(max_num_keys, fingerprint_size, fingerprints_per_bucket \\ 4) do
    num_buckets = upper_power_2(max_num_keys / fingerprints_per_bucket)
    frac = max_num_keys / num_buckets / fingerprints_per_bucket

    %Filter{
            buckets: Array.new(
              [if(frac > 0.96, do: num_buckets <<< 1, else: num_buckets),
               :fixed,
               {:default, Bucket.new(fingerprints_per_bucket)}]
            ),
            fingerprint_size: fingerprint_size,
            fingerprints_per_bucket: fingerprints_per_bucket,
            max_num_keys: max_num_keys
        }
  end

  @doc """
  Tries to insert `element` into the Cuckoo Filter.

  Returns `{:ok, filter}` if successful, otherwise returns `{:err, :full}` from which
  you should consider the Filter to be full.
  """
  @spec insert(Filter.t, any) :: {:ok, Filter.t} | {:err, :full}
  def insert(%Filter{
                     buckets: buckets,
                     fingerprint_size: bits_per_item,
                     fingerprints_per_bucket: fingerprints_per_bucket
                 } = filter, element) do
    num_buckets = Array.size(buckets)
    {fingerprint, i1} = fingerprint_and_index(element, num_buckets, bits_per_item)
    i2 = alt_index(i1, fingerprint, num_buckets)

    i1_bucket = Array.get(buckets, i1)
    case Bucket.has_room?(i1_bucket) do
      {:ok, index} ->
        {:ok, %{filter |
                buckets: Array.set(
                  buckets,
                  i1,
                  Bucket.set(i1_bucket, index, fingerprint)
                )}}

      {:err, :full} ->
        i2_bucket = Array.get(buckets, i2)
        case Bucket.has_room?(i2_bucket) do
          {:ok, index} ->
            {:ok, %{filter |
                    buckets: Array.set(
                      buckets,
                      i2,
                      Bucket.set(i2_bucket, index, fingerprint)
                    )}}

          {:err, :full} ->
            if :random.uniform(2) == 1 do
              kickout(filter, i1, fingerprint, fingerprints_per_bucket)
            else
              kickout(filter, i2, fingerprint, fingerprints_per_bucket)
            end
        end
    end
  end

  @doc """
  Checks if the Cuckoo Filter contains `element`.

  Returns `true` if does, otherwise returns `false`.
  """
  @spec contains?(Filter.t, any) :: boolean
  def contains?(%Filter{buckets: buckets, fingerprint_size: bits_per_item}, element) do
    num_buckets = Array.size(buckets)
    {fingerprint, i1} = fingerprint_and_index(element, num_buckets, bits_per_item)

    case fingerprint in Array.get(buckets, i1) do
      true -> true
      false -> i2 = alt_index(i1, fingerprint, num_buckets)
               fingerprint in Array.get(buckets, i2)
    end

  end


  # private helper functions

  @spec kickout(Filter.t, non_neg_integer, pos_integer, pos_integer, pos_integer) :: {:ok, Filter.t} | {:err, :full}
  defp kickout(filter, index, fingerprint, fingerprints_per_bucket, current_kick \\ @max_kicks)
  defp kickout(_, _, _, _, 0), do: {:err, :full}
  defp kickout(%Filter{buckets: buckets} = filter, index, fingerprint, fingerprints_per_bucket, current_kick) do
    bucket = Array.get(buckets, index)

    # randomly select an entry from the bucket
    rand = :random.uniform(fingerprints_per_bucket) - 1

    # withdraw its fingerprint
    old_fingerprint = Bucket.get(bucket, rand)

    # replace it
    bucket = Bucket.set(bucket, rand, fingerprint)
    buckets = Array.set(buckets, index, bucket)

    # find a place to put the old fingerprint
    fingerprint = old_fingerprint
    num_buckets = Array.size(buckets)
    index = alt_index(index, fingerprint, num_buckets)
    bucket = Array.get(buckets, index)

    case Bucket.has_room?(bucket) do
      {:ok, b_index} ->
        bucket = Bucket.set(bucket, b_index, fingerprint)
        buckets = Array.set(buckets, index, bucket)
        {:ok, %{filter | buckets: buckets}}
      {:err, :full} ->
        kickout(%{filter | buckets: buckets}, index, fingerprint, fingerprints_per_bucket, current_kick - 1)
    end

  end

  @spec index(pos_integer, pos_integer) :: non_neg_integer
  defp index(hash, num_buckets) do
    rem(hash, num_buckets)
  end

  @spec fingerprint(pos_integer, pos_integer) :: pos_integer
  defp fingerprint(hash, bits_per_item) do
  	hash &&& ((1 <<< bits_per_item) - 1)
  end

  # calculates the smallest power of 2 greater than or equal to n
  @spec upper_power_2(float) :: pos_integer
  defp upper_power_2(n) do
  	:math.pow(2, Float.ceil(log2(n))) |> trunc
  end

  @spec log2(float) :: float
  defp log2(n) do
    :math.log(n) / :math.log(2)
  end

  @spec hash1(any) :: pos_integer
  defp hash1(element), do: Murmur.hash(:x64_128, element)

  @spec hash2(pos_integer) :: pos_integer
  defp hash2(fingerprint), do: :erlang.phash2(fingerprint)
  #defp hash2(x), do: x * 0x5bd1e995

  defp fingerprint_and_index(element, num_buckets, bits_per_item) do
  	hash = hash1(element)
    fingerprint = fingerprint(hash, bits_per_item)
    index = index((hash >>> 32), num_buckets)
    {fingerprint, index}
  end

  defp alt_index(i1, fingerprint, num_buckets) do
  	i1 ^^^ index(hash2(fingerprint), num_buckets)
  end

end
