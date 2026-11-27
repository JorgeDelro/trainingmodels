# Changelog

## trainingmodels 0.0.3

- New
  [`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md)
  simulates the Banister impulse-response model from a `daily_load`
  object and parameters given by the user: fitness, fatigue and
  predicted performance for every day, within each athlete. The
  fitness-only model is an option of the same function (DECISIONS.md,
  D-023). Both timing conventions are offered through `same_day_load`,
  with default `"exclude"` (D-012). Initial fitness and fatigue are 0 by
  default and can be set (D-025). Missing loads are an error unless
  `missing_load = "zero"` (D-016). The result prints its model,
  convention, parameters and half-lives (A-012).
- New
  [`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md)
  gives the effect of one session on the following days,
  `time_to_recover`, `time_to_peak` and `peak_effect`; new
  [`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md)
  gives the closed-form response to constant daily training, its
  asymptote and `time_of_minimum`. Times that do not exist are `NA`
  (D-026).
- New
  [`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  and
  [`time_constant()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  convert between time constants and half-lives (D-024).
- New article “The Banister model” reproduces the example of Morton et
  al.
  1990. and discusses the limitations of the model. Nothing is fitted in
        this version.

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
