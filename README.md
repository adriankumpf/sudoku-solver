# Sudoku

Yet another implementation of Peter Norvig's Sudoku solver / constraint
propagation and search algorithm. Created for learning purposes.

To run the benchmark call

`mix run examples/benchmark.exs`

You can also solve your own puzzles using

```
$ iex -S mix

spec ='85...24..72......9..4.........1.7..23.5...9...4...........8..7..17..........36.4.'
{:ok, grid} = Sudoku.solve spec
Sudoku.display grid
```
