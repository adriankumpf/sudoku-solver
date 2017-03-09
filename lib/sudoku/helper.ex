defmodule Sudoku.Helper do
  @moduledoc """
  A separate module of functions needed at compile time.
  """

  def cross(as, bs) do
    for a <- as, b <- bs, do: [a, b]
  end

  def merge_units([l1, l2, l3]) do
    l1 ++ l2 ++ l3
  end
end

