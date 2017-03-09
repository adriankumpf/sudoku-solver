defmodule Sudoku do
  @moduledoc """
  See http://norvig.com/sudoku.html
  """

  import Enum, only: [chunk: 2, reject: 2, uniq: 1]
  import Sudoku.Helper

  ################### Default notation ###################

  @digits '123456789'
  @rows   'ABCDEFGHI'
  @cols   @digits

  @peers_list (for rs <- chunk(@rows, 3),
                   cs <- chunk(@cols, 3),
               do: cross(rs, cs)
  )

  @unit_list ((for c <- @cols, do: cross(@rows, [c])) ++
              (for r <- @rows, do: cross([r], @cols)) ++
              @peers_list)

  @squares cross(@rows, @cols)

  @units (for s <- @squares, into: %{},
          do: { s, (for u <- @unit_list, s in u, do: u) })

  @peers (for s <- @squares, into: %{},
          do: { s, @units[s] |> merge_units |> uniq |> reject(&(&1 == s))})

  def peers_list, do: @peers_list
  def unit_list,  do: @unit_list
  def squares,    do: @squares
  def units,      do: @units
  def peers,      do: @peers

  #################### Parsing a grid ####################

  def parse_grid(spec) when is_list(spec) and length(spec) == 81 do
    unless Enum.all?(spec, &accepted_char?/1), do: raise "Invalid grid spec"

    {:ok, grid_values(spec)}
  end
  def parse_grid(_), do: {:error, "Not a valid grid"}

  defp accepted_char?(c) do
    c in [?., ?0 | @digits]
  end

  defp grid_values(spec) do
    Enum.zip(@squares, spec) |> Enum.into(%{})
  end

end
