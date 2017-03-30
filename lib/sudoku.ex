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

  def parse_grid_spec(spec) do
    spec
    |> Enum.filter(& &1 in [?., ?0 | @digits])
    |> Enum.map(& [&1])
    |> grid_values
  end

  defp grid_values(spec) when length(spec) != 81 do
    raise "Invalid grid spec"
  end
  defp grid_values(spec) do
    @squares
    |> Enum.zip(spec)
    |> Enum.into(%{})
  end

  ################ Constraint Propagation ################

  def assign_into(values, initial_grid) do
    Enum.reduce(values, {:ok, initial_grid}, &do_assign_into/2)
  end

  defp do_assign_into({s, [d]}, {:ok, grid}) when d in @digits do
    assign(grid, s, d)
  end
  defp do_assign_into(_, {:ok, _} = grid), do: grid
  defp do_assign_into(_, {:error, _} = err), do: err

  # Eliminate all the other values (except d) from grid[s].
  defp assign(grid, s, d) do
    other_values = List.delete(grid[s], d)
    eliminate_values(grid, s, other_values)
  end


  defp eliminate_values(grid, s, values) do
    values
    |> Enum.reduce({{:ok, grid}, s}, &eliminate_value/2)
    |> elem(0)
  end

  defp eliminate_value(d, {{:ok, grid}, s}), do: {eliminate(grid, s, d), s}
  defp eliminate_value(_, {{:error, _}, _} = err), do: err


  defp eliminate_from_squares(grid, squares, d) do
    squares
    |> Enum.reduce({{:ok, grid}, d}, &eliminate_from_square/2)
    |> elem(0)
  end

  defp eliminate_from_square(s, {{:ok, grid}, d}), do: {eliminate(grid, s, d), d}
  defp eliminate_from_square(_, {{:error, _}, _} = err), do: err


  # Eliminate d from grid[s].
  defp eliminate(grid, s, d) do
    if not d in grid[s] do # Already eliminated
      {:ok, grid}
    else
      grid = Map.update!(grid, s, & List.delete(&1, d))

      with {:ok, grid} <- check_peers(grid, s, grid[s]),
           {:ok, grid} <- check_units(grid, s, d) do
        {:ok, grid}
      else
        err -> err
      end
    end
  end


  # (1) If a square s is reduced to one value d2,
  #     then eliminate d2 from the peers.

  defp check_peers(grid, s, [d2]) do
    eliminate_from_squares(grid, @peers[s], d2)
  end
  defp check_peers(_, _,  []) do
    {:error, "Removed last value"}
  end
  defp check_peers(grid, _, _) do
    {:ok, grid}
  end


  # (2) If a unit u is reduced to only one place
  #     for a value d, then put it there.

  defp check_units(grid, s, d) do
    @units[s]
    |> Enum.reduce({{:ok, grid}, s, d}, &check_unit/2)
    |> elem(0)
  end

  defp check_unit(_, err = {{:error, _}, _, _}), do: err
  defp check_unit(u, msg = {{:ok, grid}, s, d}) do
    dplaces = for s <- u, d in grid[s], do: s

    case length(dplaces) do
       0 -> {{:error, "No place found for inserting value"}, s, d}
       1 -> # d can only be in one place in unit; assign it there
         {assign(grid, List.first(dplaces), d), s, d}
       _ -> msg
    end
  end

  ######################## Search ########################

  # Using depth-first search and propagation, try all possible values.
  defp search({:error, _} = err), do: err
  defp search({:ok, grid}) do
    if Enum.all?(@squares, & length(grid[&1]) == 1) do
      {:ok, grid} # Solved!
    else
      {s, values} = # Chose the unfilled square s with the fewest possibilities
        grid
        |> Enum.filter(fn {_, v} -> length(v) > 1 end)
        |> Enum.min_by(fn {_, v} -> length(v) end)

      loop_until_solution_found(values, fn d -> search(assign(grid, s, d)) end)
    end
  end

  defp loop_until_solution_found([], _), do: {:error, "No solution found"}
  defp loop_until_solution_found([d|rest], searcher) do
    case searcher.(d) do
      {:error, _} -> loop_until_solution_found(rest, searcher)
      {:ok, grid} -> {:ok, grid}
    end
  end

  ######################## Display #######################

  def display(grid) do
    width =
      (for s <- @squares, do: length grid[s])
      |> Enum.max
      |> Kernel.+(1)

    line =
      '-'
      |> List.duplicate(3 * width)
      |> Enum.join("")
      |> List.duplicate(3)
      |> Enum.join("+")

    for r <- @rows do
      for c <- @cols do
        grid[[r, c]]
        |> center(width)
        |> Kernel.++(if c in '36', do: '|', else: '')
      end
      |> IO.puts

      if r in 'CF', do: IO.puts line
    end

    :ok
  end

  ######################### Solve ########################

  def solve(spec) do
    spec
    |> parse_grid_spec
    |> assign_into(@initial_grid)
    |> search
  end
end
