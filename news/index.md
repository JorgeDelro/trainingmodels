# Changelog

## trainingmodels 0.0.1

- New
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md)
  builds a complete daily calendar from session data: same-day sessions
  are summed, every day is marked as training, rest or missing, and days
  without a row are filled as rest (default) or missing, with a warning
  for long runs of filled days (DECISIONS.md, D-015 to D-017). Supports
  several athletes and an optional performance column.
- New [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) methods for
  `daily_load` objects.

## trainingmodels 0.0.0.9000

- Initial package skeleton (milestone 0). No user-facing functionality
  yet.
