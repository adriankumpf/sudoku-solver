defmodule Sudoku do
  @moduledoc """
  See http://norvig.com/sudoku.html

  Notation:
   s ... Square. A grid has 9x9=81 squares.
   d ... Digit. A dot or zero equals empty.
   u ... Unit. A collection of 9 squares.
         (Either a column, row or box)
   p ... Peer. Each square has exactly 20 peers.
         (All unique squares from its 3 units)
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

  @units_list ((for c <- @cols, do: cross(@rows, [c])) ++
               (for r <- @rows, do: cross([r], @cols)) ++
               @peers_list)

  @squares cross(@rows, @cols)

  @units (for s <- @squares, into: %{},
          do: {s, (for u <- @units_list, s in u, do: u)})

  @peers (for s <- @squares, into: %{},
          do: {s, @units[s] |> merge_units |> uniq |> reject(&(&1 == s))})

  @initial_grid (for s <- @squares, into: %{}, do: {s, @digits})

  def peers_list, do: @peers_list
  def units_list, do: @units_list
  def squares,    do: @squares
  def units,      do: @units
  def peers,      do: @peers

  #################### Parsing a grid ####################

  def parse_grid(spec) do
    spec
    |> Enum.filter(& &1 in [?., ?0 | @digits])
    |> grid_values
  end

  defp grid_values(spec) when length(spec) != 81 do
    raise "Invalid grid spec"
  end
  defp grid_values(spec) do
    @squares |> Enum.zip(spec) |> Enum.into(%{})
  end

  ################ Constraint Propagation ################

  def assign_into(values, grid) do
    Enum.reduce(values, {:ok, grid}, &do_assign_into/2)
  end

  defp do_assign_into({s, d}, {:ok, grid}) when d in @digits, do: assign(grid, s, d)
  defp do_assign_into(_, {:ok, _} = grid), do: grid
  defp do_assign_into(_, {:error, _} = err), do: err

  @doc """
  Eliminate all the other values (except d) from grid[s].
  """
  def assign(grid, s, d) do
    other_values = List.delete(grid[s], d)
    eliminate_values(grid, s, other_values)
  end


  def eliminate_values(grid, s, values) do
    values
    |> Enum.reduce({{:ok, grid}, s}, &eliminate_value/2)
    |> elem(0)
  end

  defp eliminate_value(d, {{:ok, grid}, s}), do: {eliminate(grid, s, d), s}
  defp eliminate_value(_, {{:error, _}, _} = msg), do: msg


  def eliminate_from_squares(grid, squares, d) do
    squares
    |> Enum.reduce({{:ok, grid}, d}, &eliminate_from_square/2)
    |> elem(0)
  end

  defp eliminate_from_square(s, {{:ok, grid}, d}), do: {eliminate(grid, s, d), d}
  defp eliminate_from_square(_, {{:error, _}, _} = msg), do: msg


  @doc """
  Eliminate d from grid[s].
  """
  def eliminate(grid, s, d) do
    if not d in grid[s] do
      {:ok, grid} # Already eliminated
    else
      new_grid = Map.update!(grid, s, & List.delete(&1, d))

      with {:ok, grid1} <- check_peers(new_grid, s, new_grid[s]),
           {:ok, grid2} <- check_units(grid1, s, d) do
        {:ok, grid2}
      else
        err -> err
      end
    end
  end


  @doc """
   If a square s is reduced to one value d2, then eliminate d2 from the peers.
  """
  def check_peers(grid, s, [d2]) do
    eliminate_from_squares(grid, @peers[s], d2)
  end
  def check_peers(_, _,  []) do
    {:error, :contradiction} # removed last value
  end
  def check_peers(grid, _, _) do
    {:ok, grid}
  end

  @doc """
  If a unit u is reduced to only one place for a value d, then put it there.
  """
  defp check_units(grid, s, d) do
    @units[s]
    |> Enum.reduce({{:ok, grid}, s, d}, &check_unit/2)
    |> elem(0)
  end

  defp check_unit(u, msg = {{:ok, grid}, s, d}) do
    dplaces = for s <- u, d in grid[s], do: s

    case length(dplaces) do
       0 ->
         # no place for this value
         {{:error, :contradiction}, s, d}
       1 ->
         # d can only be in one place in unit; assign it there
         {assign(grid, List.first(dplaces), d), s, d}
       _ -> msg
    end
  end


  defp search({:ok, grid}) do
    grid
  end
  defp search(_) do
    {:error, "Failed earlier"}
  end

  # Sudoku.main '003020600900305001001806400008102900700000008006708200002609500800203009005010300'

  def main(spec) do
    spec
    |> parse_grid
    |> assign_into(@initial_grid)
    |> search
  end

end
