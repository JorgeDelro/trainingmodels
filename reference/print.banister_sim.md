# Print a Banister simulation

Prints a header with the model, the timing convention, the parameters
and the half-life of each time constant (DECISIONS.md, A-012 and D-024),
followed by the first rows of the simulation.

## Usage

``` r
# S3 method for class 'session_response'
print(x, ...)

# S3 method for class 'constant_training'
print(x, ...)

# S3 method for class 'banister_sim'
print(x, n = 10, ...)
```

## Arguments

- x:

  A `banister_sim` object, from
  [`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md).

- ...:

  Passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

- n:

  Number of rows to print.

## Value

`x`, invisibly.

## Examples

``` r
x <- as_daily_load(
  data.frame(date = as.Date("2026-01-01") + 0:9, load = rep(100, 10)),
  date = "date", load = "load"
)
print(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15), n = 5)
#> <banister_sim> Banister model simulation: two-component model
#> Timing convention: same_day_load = "exclude" (a day's load affects performance from the next day)
#> Parameters: p0 = 0, k1 = 1, k2 = 2
#> Time constants: tau1 = 45 days (half-life 31.19 days), tau2 = 15 days (half-life 10.4 days)
#> Initial state: fitness 0, fatigue 0
#> Nothing is fitted: values are simulated from the parameters given.
#> 
#>   athlete       date load   fitness  fatigue  predicted
#> 1       1 2026-01-01  100   0.00000   0.0000    0.00000
#> 2       1 2026-01-02  100  97.80229  93.5507  -89.29911
#> 3       1 2026-01-03  100 193.45516 181.0680 -168.68090
#> 4       1 2026-01-04  100 287.00586 262.9411 -238.87635
#> 5       1 2026-01-05  100 378.50058 339.5339 -300.56730
#> # ... 5 more rows
```
