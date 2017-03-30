import Sudoku

"./examples/easy50.txt"   |> from_file |> solve_all("easy")
"./examples/top95.txt"    |> from_file |> solve_all("hard")
"./examples/hardest.txt"  |> from_file |> solve_all("hardest")
(for _ <- 0..999, do: random_puzzle()) |> solve_all("random", 1.0)
