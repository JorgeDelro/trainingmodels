# Session RPE load

Computes the session rating of perceived exertion (RPE) load of Foster
(1998) and Foster et al. (2001): the RPE of the session multiplied by
its duration in minutes (MODELS.md, M-10).

## Usage

``` r
srpe_load(rpe, duration)
```

## Arguments

- rpe:

  Numeric vector of session RPE values, each between 0 and 10 or `NA`.

- duration:

  Numeric vector of session durations in minutes, each `>= 0` or `NA`.
  Must have the same length as `rpe`, or one of the two must have length
  1.

## Value

A numeric vector, `rpe * duration`. `NA` in either argument gives `NA`.

## Details

\$\$w = \mathrm{RPE} \times D\$\$

## Collecting the data

- **RPE** is rated on the 0-10 category-ratio scale: one global rating
  for the whole session, asked about 30 minutes after it ends.

- **Duration** is the duration in minutes of the entire session,
  including warm-up, cool-down and recovery intervals.

Several sessions on the same day are summed when the loads are passed to
[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

Session RPE load is in arbitrary units. Comparing it across athletes
needs care.

## References

Foster C (1998). Monitoring training in athletes with reference to
overtraining syndrome. *Medicine and Science in Sports and Exercise*,
30(7), 1164-1168.

Foster C, Florhaug JA, Franklin J, et al. (2001). A new approach to
monitoring exercise training. *Journal of Strength and Conditioning
Research*, 15(1), 109-115.

## See also

[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md)
to build the daily series,
[`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md)
and
[`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md)
to describe it.

## Examples

``` r
# The week of Foster (1998), Table 1
srpe_load(rpe = c(5, 7, 2, 6, 7, 2, 7),
          duration = c(180, 120, 20, 90, 75, 20, 120))
#> [1] 900 840  40 540 525  40 840
```
