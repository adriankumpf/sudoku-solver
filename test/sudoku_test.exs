defmodule SudokuTest do
  use ExUnit.Case
  doctest Sudoku

  test "the basic notions" do
    assert length(Sudoku.peers_list) == 9
    assert length(Sudoku.unit_list)  == 27
    assert length(Sudoku.squares)    == 81

    for s <- Sudoku.squares do
      assert length(Sudoku.units[s]) == 3
      assert length(Sudoku.peers[s]) == 20
    end

    assert Sudoku.units['C2'] == [['A2', 'B2', 'C2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2'],
                                  ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9'],
                                  ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3']]

    assert Sudoku.peers['C2'] == ['A2', 'B2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2',
                                  'C1', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9',
                                  'A1', 'A3', 'B1', 'B3']
  end

  test "parsing an empty grid spec" do
    empty_grid_spec = List.duplicate(?., 81)
    {:ok, grid} = Sudoku.parse_grid(empty_grid_spec)

    assert Enum.count(grid) == 81

    for {_k, v} <- grid do
      assert v == '123456789'
    end
  end

end
