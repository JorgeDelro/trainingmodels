# Changelog

## trainingmodels 0.0.2

- New
  [`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md)
  computes session RPE load, RPE x duration (Foster 1998; Foster et
  al. 2001).
- New
  [`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md)
  gives the rolling sum and mean of the daily load over a window of
  days, and
  [`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md)
  gives Foster’s monotony and strain over a rolling window (7 days by
  default). Both work within each athlete, return `NA` for windows with
  a missing day, and offer both timing options through `same_day_load`,
  with default `"include"` (DECISIONS.md, D-020 to D-022).
- Functions that take a `daily_load` now check it first and refuse an
  object that was changed after it was built, for example by subsetting
  ([\#4](https://github.com/JorgeDelro/trainingmodels/issues/4)).
- New article “Monotony and strain” reproduces Foster (1998, Table 1)
  and discusses the limitations of the descriptors.
- Ratios of rolling loads and EWMA-based loads are left to the ACWR
  package (D-019).

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
