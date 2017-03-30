# Sudoku Solver

Yet another implementation of Peter Norvig's Sudoku solver / constraint
propagation and search algorithm. Created for learning purposes.

To run the benchmark call

```bash
$ mix run examples/benchmark.exs

Solved 50 of 50 easy puzzles (avg 0.01s, max 0.01s)
Solved 95 of 95 hard puzzles (avg 0.02s, max 0.05s)
Solved 11 of 11 hardest puzzles (avg 0.01s, max 0.03s)
Solved 1000 of 1000 random puzzles (avg 0.01s, max 0.01s)
```

You can also solve your own puzzles using

```elixir
$ iex -S mix

spec = '85...24..72......9..4.........1.7..23.5...9...4...........8..7..17..........36.4.'
{:ok, grid} = Sudoku.solve(spec)
Sudoku.display(grid)
```
