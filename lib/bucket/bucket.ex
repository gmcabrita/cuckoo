defmodule Cuckoo.Bucket do
  @moduledoc """
  This module implements a Bucket.
  """

  @type t :: :array.array(pos_integer)

  @spec new(pos_integer) :: t
  def new(n) do
    :array.new(n, [{ :fixed, true }, { :default, 0 }])
  end

end
