# Rolling training load

Computes, for every day, the sum and the mean of the daily loads over a
window of `window` days, within each athlete (MODELS.md, M-11).

## Usage

``` r
rolling_load(x, window = 7, same_day_load = c("include", "exclude"))
```

## Arguments

- x:

  A `daily_load` object, from
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).
  It is checked first; an object changed after it was built (for example
  by subsetting) must be rebuilt with
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

- window:

  Length of the window in days, a single whole number `>= 1`.

- same_day_load:

  Whether the window ends on the current day (`"include"`, the default)
  or on the previous day (`"exclude"`).

## Value

A data frame with one row per row of `x`, in the same order, and the
columns `athlete`, `date`, `load`, `rolling_sum` and `rolling_mean`. The
attributes `window` and `same_day_load` record the arguments used.

## Formula

For the daily loads \\w(1), \dots, w(T)\\ of one athlete and a window of
\\k\\ days:

- `same_day_load = "include"` (the default): the window ends on the
  current day, \$\$S(t) = \sum\_{j = t-k+1}^{t} w(j),\$\$ defined for
  \\t \ge k\\;

- `same_day_load = "exclude"`: the window ends on the previous day,
  \$\$S(t) = \sum\_{j = t-k}^{t-1} w(j),\$\$ defined for \\t \ge k +
  1\\. This is the form of Carey et al. (2017, Eq. 1).

The rolling mean is \\S(t) / k\\. The two options are related by
"exclude" on day \\t\\ = "include" on day \\t - 1\\.

## Timing option and default

The default is `same_day_load = "include"` (DECISIONS.md, D-021). This
differs from the impulse-response models, whose default is "exclude"
(D-012).

## Missing and rest days

A day with a missing load makes every window that contains it `NA`
(D-016); missing loads are never filled. Windows that do not fit in the
series (the first \\k - 1\\ days with "include", the first \\k\\ with
"exclude") are `NA`: there are no partial windows. Rest days count as
load 0. Days added by
[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md)
count as rest or as missing according to its `gaps` argument.

## Acute

chronic workload ratio: Ratios of rolling loads and EWMA-based loads are
not provided here: see the ACWR package (DECISIONS.md, D-019).

## References

Carey DL, Blanch P, Ong K-L, et al. (2017). Training loads and injury
risk in Australian football—differing acute:chronic workload ratios
influence match injury risk. *British Journal of Sports Medicine*, 51,
1215-1220.

## See also

[`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md),
[`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md),
[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

## Examples

``` r
x <- as_daily_load(
  data.frame(date = as.Date("2026-01-01") + 0:9,
             load = c(300, 0, 450, 500, 0, 0, 620, 410, 380, 0)),
  date = "date", load = "load"
)
rolling_load(x, window = 3)
#>    athlete       date load rolling_sum rolling_mean
#> 1        1 2026-01-01  300          NA           NA
#> 2        1 2026-01-02    0          NA           NA
#> 3        1 2026-01-03  450         750     250.0000
#> 4        1 2026-01-04  500         950     316.6667
#> 5        1 2026-01-05    0         950     316.6667
#> 6        1 2026-01-06    0         500     166.6667
#> 7        1 2026-01-07  620         620     206.6667
#> 8        1 2026-01-08  410        1030     343.3333
#> 9        1 2026-01-09  380        1410     470.0000
#> 10       1 2026-01-10    0         790     263.3333
rolling_load(x, window = 3, same_day_load = "exclude")
#>    athlete       date load rolling_sum rolling_mean
#> 1        1 2026-01-01  300          NA           NA
#> 2        1 2026-01-02    0          NA           NA
#> 3        1 2026-01-03  450          NA           NA
#> 4        1 2026-01-04  500         750     250.0000
#> 5        1 2026-01-05    0         950     316.6667
#> 6        1 2026-01-06    0         950     316.6667
#> 7        1 2026-01-07  620         500     166.6667
#> 8        1 2026-01-08  410         620     206.6667
#> 9        1 2026-01-09  380        1030     343.3333
#> 10       1 2026-01-10    0        1410     470.0000
```
