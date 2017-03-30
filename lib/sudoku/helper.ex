defmodule Sudoku.Helper do
  @moduledoc """
  A separate module of functions, some of which are needed at compile time.
  """

  def cross(as, bs) do
    for a <- as, b <- bs, do: [a, b]
  end

  def merge_units([l1, l2, l3]) do
    l1 ++ l2 ++ l3
  end

  def center(chars, width, c \\ ?\s) when length(chars) < width do
    fill = width - length(chars)
    s = List.duplicate(c, div(fill, 2))
    a = List.duplicate(c, rem(fill, 2))
    s ++ chars ++ s ++ a
  end

  def measure(func) do
    {time, result} = :timer.tc(func)
    {time/1_000_000, result}
  end
end

