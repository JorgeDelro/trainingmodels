# Monotony and strain

``` r

library(trainingmodels)
```

## Theory

**Session RPE load** (Foster 1998; Foster et al. 2001; MODELS.md, M-10).
The load of a session is its rating of perceived exertion multiplied by
its duration:

``` math
w = \mathrm{RPE} \times D
```

The RPE is one global rating of the whole session on the 0-10
category-ratio scale, asked about 30 minutes after the session ends. The
duration $`D`$ is in minutes and covers the entire session, including
warm-up, cool-down and recovery intervals. Sessions of the same day are
summed, so each day has one load.

**Monotony and strain** (Foster 1998; MODELS.md, M-12). For the daily
loads of a week,

``` math
\text{monotony} = \frac{\text{mean daily load}}{\text{SD of the daily loads}},
\qquad
\text{strain} = \text{weekly load} \times \text{monotony}.
```

The standard deviation is the sample standard deviation (divisor
$`n - 1`$). Monotony is high when the loads of the week are similar to
each other; strain combines the amount of training with its monotony.

The package computes both over a rolling window of `window` days (7 by
default), every day. The argument `same_day_load` chooses whether the
window ends on the current day (`"include"`, the default) or on the
previous day (`"exclude"`). Rest days count as load 0. A window that
contains a missing day gives `NA`. When all loads of a window are equal
the standard deviation is 0, and monotony and strain are `NA`.

Sources: Foster C (1998). Monitoring training in athletes with reference
to overtraining syndrome. *Medicine and Science in Sports and Exercise*,
30(7), 1164-1168. Foster C, Florhaug JA, Franklin J, et al. (2001). A
new approach to monitoring exercise training. *Journal of Strength and
Conditioning Research*, 15(1), 109-115.

## Computation

Foster (1998, Table 1) gives one week of training with the duration and
the RPE of each day.

``` r

week <- data.frame(
  date = as.Date("2026-01-04") + 0:6,
  duration = c(180, 120, 20, 90, 75, 20, 120),
  rpe = c(5, 7, 2, 6, 7, 2, 7)
)
week$load <- srpe_load(week$rpe, week$duration)
week
#>         date duration rpe load
#> 1 2026-01-04      180   5  900
#> 2 2026-01-05      120   7  840
#> 3 2026-01-06       20   2   40
#> 4 2026-01-07       90   6  540
#> 5 2026-01-08       75   7  525
#> 6 2026-01-09       20   2   40
#> 7 2026-01-10      120   7  840
```

The daily loads are 900, 840, 40, 540, 525, 40 and 840, as in the table.
They are turned into a daily series and described with a 7-day window:

``` r

x <- as_daily_load(week, date = "date", load = "load")
out <- monotony_strain(x, window = 7)
out
#>   athlete       date load window_load mean_load  sd_load monotony   strain
#> 1       1 2026-01-04  900          NA        NA       NA       NA       NA
#> 2       1 2026-01-05  840          NA        NA       NA       NA       NA
#> 3       1 2026-01-06   40          NA        NA       NA       NA       NA
#> 4       1 2026-01-07  540          NA        NA       NA       NA       NA
#> 5       1 2026-01-08  525          NA        NA       NA       NA       NA
#> 6       1 2026-01-09   40          NA        NA       NA       NA       NA
#> 7       1 2026-01-10  840        3725  532.1429 367.2857 1.448853 5396.976
```

Only the seventh day has a complete window. Its values agree with the
printed ones:

``` r

day7 <- out[7, ]
data.frame(
  quantity = c("Weekly load", "Mean daily load", "SD", "Monotony", "Strain"),
  printed = c(3725, 532, 367, 1.44, 5397),
  package = c(day7$window_load, day7$mean_load, day7$sd_load,
              day7$monotony, day7$strain)
)
#>          quantity printed     package
#> 1     Weekly load 3725.00 3725.000000
#> 2 Mean daily load  532.00  532.142857
#> 3              SD  367.00  367.285733
#> 4        Monotony    1.44    1.448853
#> 5          Strain 5397.00 5396.975613
```

The monotony is 1.449. Foster prints 1.44: the value is truncated, not
rounded. The printed strain, 5397, is computed from the unrounded
monotony (MODELS.md, discrepancy log).

## Limitations

- Foster 1998 is an observational study of 25 athletes; thresholds were
  individual and chosen after the fact to explain illnesses; they are
  not validated cut-offs.
- In that study, 52% of the excursions above the monotony threshold and
  59% of those above the strain threshold were not followed by illness.
- Monotony divides by a standard deviation: it is unstable when the days
  of the week are similar and undefined when they are equal; a single
  rest day changes it substantially.
- The result depends on whether rest days count as zero. Foster does not
  say; this package counts them.
- Session RPE load is in arbitrary units and is not comparable across
  athletes without care.
