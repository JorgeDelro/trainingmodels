# Print a daily training-load series

Prints a header (number of athletes, date range, number of days, counts
by day state and number of filled days) followed by the first rows.

## Usage

``` r
# S3 method for class 'daily_load'
print(x, n = 10, ...)
```

## Arguments

- x:

  A `daily_load` object, from
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

- n:

  Number of rows to show.

- ...:

  Passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`x`, invisibly.

## Examples

``` r
x <- as_daily_load(
  data.frame(date = c("2026-01-01", "2026-01-03"), load = c(300, 250)),
  date = "date", load = "load"
)
#> Filled 1 day without a row as rest (load 0). Use gaps = "missing" to treat filled days as missing.
print(x)
#> <daily_load> 1 athlete, 2026-01-01 to 2026-01-03, 3 days
#> Days: 2 training, 1 rest, 0 missing; 1 filled (as rest)
#> Load column: load
#> 
#>   athlete       date load   status n_sessions filled
#> 1       1 2026-01-01  300 training          1  FALSE
#> 2       1 2026-01-02    0     rest          0   TRUE
#> 3       1 2026-01-03  250 training          1  FALSE
```
