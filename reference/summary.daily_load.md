# Summarise a daily training-load series by athlete

Summarise a daily training-load series by athlete

## Usage

``` r
# S3 method for class 'daily_load'
summary(object, ...)
```

## Arguments

- object:

  A `daily_load` object, from
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

- ...:

  Not used.

## Value

A data frame with one row per athlete and the columns `athlete`,
`first_date`, `last_date`, `n_days`, `n_training`, `n_rest`,
`n_missing`, `n_filled`, `longest_filled_run` (the longest run of
consecutive filled days) and `n_performance` (days with a non-`NA`
performance value; 0 if there is no performance column).

## Examples

``` r
x <- as_daily_load(
  data.frame(date = c("2026-01-01", "2026-01-03"), load = c(300, 250)),
  date = "date", load = "load"
)
#> Filled 1 day without a row as rest (load 0). Use gaps = "missing" to treat filled days as missing.
summary(x)
#>   athlete first_date  last_date n_days n_training n_rest n_missing n_filled
#> 1       1 2026-01-01 2026-01-03      3          2      1         0        1
#>   longest_filled_run n_performance
#> 1                  1             0
```
