# Simulate the Banister impulse-response model

Computes fitness, fatigue and predicted performance for every day of a
daily training-load series, within each athlete, from parameters given
by the user (MODELS.md, M-01 to M-03). Nothing is fitted: this version
only simulates.

## Usage

``` r
simulate_banister(
  x,
  k1,
  tau1,
  k2 = NULL,
  tau2 = NULL,
  p0 = 0,
  model = c("two_component", "fitness_only"),
  same_day_load = c("exclude", "include"),
  initial_fitness = 0,
  initial_fatigue = 0,
  missing_load = c("error", "zero")
)
```

## Arguments

- x:

  A `daily_load` object, from
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).
  It is checked first; an object changed after it was built (for example
  by subsetting) must be rebuilt with
  [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).

- k1:

  Gain of fitness, a single finite number `>= 0`.

- tau1:

  Time constant of fitness in days, a single finite number `> 0`.
  Arguments are time constants, never half-lives (D-024): see
  [`time_constant()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  to convert a half-life.

- k2:

  Gain of fatigue, a single finite number `>= 0`. Required for the
  two-component model; must not be given for the fitness-only model.

- tau2:

  Time constant of fatigue in days, a single finite number `> 0`.
  Required for the two-component model; must not be given for the
  fitness-only model.

- p0:

  Baseline performance, a single finite number.

- model:

  `"two_component"` (the default; fitness and fatigue) or
  `"fitness_only"` (D-023).

- same_day_load:

  Timing convention: `"exclude"` (the default) or `"include"`. See the
  section on the timing convention.

- initial_fitness, initial_fatigue:

  Fitness and fatigue on day 0, single finite numbers `>= 0`. The
  fitness-only model has no fatigue, so `initial_fatigue` must be 0.

- missing_load:

  What to do with missing loads: `"error"` (the default) or `"zero"` to
  count them as load 0.

## Value

An object of class `c("banister_sim", "data.frame")` with one row per
row of `x`, in the same order, and the columns `athlete`, `date`,
`load`, `fitness`, `fatigue` (`NA` for the fitness-only model),
`predicted` and, if `x` has a performance column, `observed`. The
attributes `model`, `same_day_load`, `parameters` (named numeric vector)
and `initial_state` record the arguments used. Its print method shows
them, with the half-life of each time constant.

## Formula

Fitness \\g\\ and fatigue \\h\\ are exponential filters of the daily
load \\w\\ with time constants \\\tau_1\\ and \\\tau_2\\ (MODELS.md,
M-01). The two-component model (M-02) predicts \$\$p(t) = p_0 +
k_1\\g(t) - k_2\\h(t),\$\$ and the fitness-only model (M-03) predicts
\$\$p(t) = p_0 + k_1\\g(t).\$\$ The columns `fitness` and `fatigue` are
\\g\\ and \\h\\ without their gains. They are computed in recursive
form.

## Timing convention and default

- `same_day_load = "exclude"` (the default; Busso & Chalencon 2023): the
  load of day \\t\\ affects performance from day \\t + 1\\, \$\$g(t) =
  \[g(t-1) + w(t-1)\]\\e^{-1/\tau}.\$\$ This corresponds to a
  performance test done before that day's training.

- `same_day_load = "include"` (Morton et al. 1990, Eqs. 4-5): the load
  of day \\t\\ counts on day \\t\\ at full weight, \$\$g(t) =
  g(t-1)\\e^{-1/\tau} + w(t).\$\$

The two conventions give different numbers: gains obtained under one are
not comparable with the other. The default "exclude" (DECISIONS.md,
D-012) differs from the default of the load descriptors such as
[`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md),
which is "include" (D-021).

## Initial state

Fitness and fatigue start from `initial_fitness` and `initial_fatigue`
on day 0, both 0 by default (D-025). An initial value \\g_0\\ adds
\\g_0\\e^{-t/\tau}\\ to day \\t\\ under both conventions (MODELS.md,
M-01). Each athlete starts from the same initial state on their first
day.

## Missing loads

Missing loads are never replaced silently (D-016). By default a series
with a missing load is an error that names the first missing day. With
`missing_load = "zero"` missing loads count as load 0 and a message says
how many; the `load` column of the result still shows them as `NA`.

## References

Morton RH, Fitz-Clarke JR, Banister EW (1990). Modeling human
performance in running. *Journal of Applied Physiology*, 69(3),
1171-1177.

Busso T, Chalencon S (2023). Validity and accuracy of impulse-response
models for modeling and predicting training effects on performance of
swimmers. *Medicine & Science in Sports & Exercise*, 55(7), 1274-1285.

Marchal A, Benazieb O, Weldegebriel Y, Méline T, Imbach F (2025).
Statistical flaws of the fitness-fatigue sports performance prediction
model. *Scientific Reports*, 15, 3706.

## See also

[`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md)
for the response to a single session,
[`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md)
for constant daily training,
[`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md),
[`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md).
The article "The Banister model" on the package website discusses the
limitations of the model.

## Examples

``` r
# Morton et al. (1990): load 100 on days 1-60, then 60 days of rest
x <- as_daily_load(
  data.frame(date = as.Date("2026-01-01") + 0:119,
             load = c(rep(100, 60), rep(0, 60))),
  date = "date", load = "load"
)
sim <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                         same_day_load = "include")
sim
#> <banister_sim> Banister model simulation: two-component model
#> Timing convention: same_day_load = "include" (a day's load counts on the same day)
#> Parameters: p0 = 0, k1 = 1, k2 = 2
#> Time constants: tau1 = 45 days (half-life 31.19 days), tau2 = 15 days (half-life 10.4 days)
#> Initial state: fitness 0, fatigue 0
#> Nothing is fitted: values are simulated from the parameters given.
#> 
#>    athlete       date load  fitness  fatigue predicted
#> 1        1 2026-01-01  100 100.0000 100.0000 -100.0000
#> 2        1 2026-01-02  100 197.8023 193.5507 -189.2991
#> 3        1 2026-01-03  100 293.4552 281.0680 -268.6809
#> 4        1 2026-01-04  100 387.0059 362.9411 -338.8764
#> 5        1 2026-01-05  100 478.5006 439.5339 -400.5673
#> 6        1 2026-01-06  100 567.9845 511.1871 -454.3896
#> 7        1 2026-01-07  100 655.5018 578.2191 -500.9363
#> 8        1 2026-01-08  100 741.0958 640.9280 -540.7602
#> 9        1 2026-01-09  100 824.8086 699.5926 -574.3766
#> 10       1 2026-01-10  100 906.6817 754.4738 -602.2658
#> # ... 110 more rows
which.min(sim$predicted)
#> [1] 16

# Fitness-only model, default convention "exclude"
simulate_banister(x, k1 = 1, tau1 = 45, model = "fitness_only")
#> <banister_sim> Banister model simulation: fitness-only model
#> Timing convention: same_day_load = "exclude" (a day's load affects performance from the next day)
#> Parameters: p0 = 0, k1 = 1
#> Time constants: tau1 = 45 days (half-life 31.19 days)
#> Initial state: fitness 0
#> Nothing is fitted: values are simulated from the parameters given.
#> 
#>    athlete       date load   fitness fatigue predicted
#> 1        1 2026-01-01  100   0.00000      NA   0.00000
#> 2        1 2026-01-02  100  97.80229      NA  97.80229
#> 3        1 2026-01-03  100 193.45516      NA 193.45516
#> 4        1 2026-01-04  100 287.00586      NA 287.00586
#> 5        1 2026-01-05  100 378.50058      NA 378.50058
#> 6        1 2026-01-06  100 467.98451      NA 467.98451
#> 7        1 2026-01-07  100 555.50185      NA 555.50185
#> 8        1 2026-01-08  100 641.09580      NA 641.09580
#> 9        1 2026-01-09  100 724.80864      NA 724.80864
#> 10       1 2026-01-10  100 806.68172      NA 806.68172
#> # ... 110 more rows
```
