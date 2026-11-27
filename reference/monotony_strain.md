# Training monotony and strain

Computes Foster's (1998) training monotony and strain for every day,
over a rolling window of `window` days (7 by default), within each
athlete (MODELS.md, M-12).

## Usage

``` r
monotony_strain(x, window = 7, same_day_load = c("include", "exclude"))
```

## Arguments

- x:

  A `daily_load` object, from
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).
  It is checked first; an object changed after it was built (for example
  by subsetting) must be rebuilt with
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

- window:

  Length of the window in days, a single whole number `>= 2`.

- same_day_load:

  Whether the window ends on the current day (`"include"`, the default)
  or on the previous day (`"exclude"`).

## Value

A data frame with one row per row of `x`, in the same order, and the
columns `athlete`, `date`, `load`, `window_load`, `mean_load`,
`sd_load`, `monotony` and `strain`. The attributes `window` and
`same_day_load` record the arguments used.

## Formula

For the loads of the window, \$\$\mathrm{monotony} =
\frac{\mathrm{mean\\ load}}{\mathrm{SD\\ of\\ the\\ loads}}, \qquad
\mathrm{strain} = \mathrm{window\\ load} \times \mathrm{monotony},\$\$
where the window load is the sum of the loads and the SD is the sample
standard deviation (divisor \\k - 1\\). Foster (1998) defines them over
a week; the package uses a rolling window computed every day (D-022).
The window is the one of
[`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md)
(MODELS.md, M-11).

## Timing option and default

With `same_day_load = "include"` (the default) the window ends on the
current day; with `"exclude"` it ends on the previous day. The default
differs from the impulse-response models, whose default is "exclude"
(DECISIONS.md, D-021 and D-012).

## Missing, rest and equal days

- A day with a missing load makes every window that contains it `NA` in
  every result column (D-016). Windows that do not fit in the series are
  `NA`: there are no partial windows.

- Rest days count as load 0. Foster (1998) does not say how rest days
  are treated; the result depends on this choice.

- When all loads of the window are equal (for example seven rest days),
  `sd_load` is 0 and `monotony` and `strain` are `NA` (D-022). Equality
  is tested on the loads themselves, not on the computed standard
  deviation.

Monotony divides by a standard deviation, so it is unstable when the
days of the window are similar. The article "Monotony and strain" on the
package website discusses its limitations.

## Acute

chronic workload ratio: Ratios of rolling loads and EWMA-based loads are
not provided here: see the ACWR package (DECISIONS.md, D-019).

## References

Foster C (1998). Monitoring training in athletes with reference to
overtraining syndrome. *Medicine and Science in Sports and Exercise*,
30(7), 1164-1168.

## See also

[`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md),
[`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md),
[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

## Examples

``` r
# The week of Foster (1998), Table 1
week <- data.frame(
  date = as.Date("2026-01-04") + 0:6,
  load = srpe_load(rpe = c(5, 7, 2, 6, 7, 2, 7),
                   duration = c(180, 120, 20, 90, 75, 20, 120))
)
x <- as_daily_load(week, date = "date", load = "load")
monotony_strain(x)
#>   athlete       date load window_load mean_load  sd_load monotony   strain
#> 1       1 2026-01-04  900          NA        NA       NA       NA       NA
#> 2       1 2026-01-05  840          NA        NA       NA       NA       NA
#> 3       1 2026-01-06   40          NA        NA       NA       NA       NA
#> 4       1 2026-01-07  540          NA        NA       NA       NA       NA
#> 5       1 2026-01-08  525          NA        NA       NA       NA       NA
#> 6       1 2026-01-09   40          NA        NA       NA       NA       NA
#> 7       1 2026-01-10  840        3725  532.1429 367.2857 1.448853 5396.976
```
