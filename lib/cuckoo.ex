defmodule Cuckoo do
  @moduledoc """
  This module implements a Cuckoo Filter.
  """

  use Bitwise

  defmodule Filter do
    defstruct [
            :buckets,
            :fingerprint_size,
            :fingerprints_per_bucket,
            :max_num_keys
        ]

    @type t ::
    %Filter{
            buckets: :array.array(Cuckoo.Bucket.t),
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
            buckets: :array.new(
              if(frac > 0.96, do: num_buckets <<< 1, else: num_buckets),
              [{ :fixed, true },
               { :default, Cuckoo.Bucket.new(fingerprints_per_bucket) }]
            ),
            fingerprint_size: fingerprint_size,
            fingerprints_per_bucket: fingerprints_per_bucket,
            max_num_keys: max_num_keys
        }
  end

  # private helper functions

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
