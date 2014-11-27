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

  @spec insert(Filter.t, any) :: {:ok, Filter.t} | {:err, :full}
  def insert(%Filter{
                     buckets: buckets,
                     fingerprint_size: bits_per_item,
                     fingerprints_per_bucket: fingerprints_per_bucket
                 } = filter, element) do
    {h1, fingerprint, h2} = hash(element, bits_per_item)

    size = Array.size(buckets)
    i1 = index(h1, size)
    i2 = index(h2, size)

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

  @spec contains?(Filter.t, any) :: boolean
  def contains?(%Filter{buckets: buckets, fingerprint_size: bits_per_item}, element) do
    {h1, fingerprint, h2} = hash(element, bits_per_item)

    size = Array.size(buckets)
    i1 = index(h1, size)
    i2 = index(h2, size)

    if fingerprint in Array.get(buckets, i1)
    || fingerprint in Array.get(buckets, i2) do
      true
    else
      false
    end
  end


  # private helper functions

  @spec kickout(Filter.t, non_neg_integer, pos_integer, pos_integer, pos_integer) :: {:ok, Filter.t} | {:err, :full}
  defp kickout(filter, index, fingerprint, fingerprints_per_bucket, current_kick \\ @max_kicks)
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
    index = index ^^^ :erlang.phash2(fingerprint)
    bucket = Array.get(buckets, index)

    case Cuckoo.has_room?(bucket) do
      {:ok, b_index} ->
        bucket = Cuckoo.set(bucket, b_index, fingerprint)
        buckets = Array.set(buckets, index, bucket)
        {:ok, %{filter | buckets: buckets}}
      {:err, :full} ->
        kickout(%{filter | buckets: buckets}, index, fingerprint, fingerprints_per_bucket, current_kick - 1)
    end

  end
  defp kickout(_, _, _, _, 0) do
  	{:err, :full}
  end

  @spec index(pos_integer, pos_integer) :: non_neg_integer
  defp index(hash, num_buckets) do
    rem(hash, num_buckets)
  end

  @spec fingerprint(pos_integer, pos_integer) :: pos_integer
  defp fingerprint(hash, bits_per_item) do
  	hash &&& ((1 <<< bits_per_item) - 1)
  end

  @spec hash(any, pos_integer) :: {pos_integer, pos_integer, pos_integer}
  defp hash(element, bits_per_item) do
    h1 = Murmur.hash(:x64_128, element)
    fingerprint = fingerprint(h1, bits_per_item)
    h2 = h1 ^^^ :erlang.phash2(fingerprint)

    {h1, fingerprint, h2}
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

end
