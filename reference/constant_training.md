# Response to constant daily training

Computes fitness, fatigue and predicted performance when the same load
is done every day from day 1, with the closed forms of Morton et al.
(1990, Eqs. 6, 9-11), the asymptote of predicted performance and the day
of poorest performance (MODELS.md, M-04). Nothing is fitted: the
parameters are given by the user. The initial state is 0.

## Usage

``` r
constant_training(
  load,
  k1,
  tau1,
  k2 = NULL,
  tau2 = NULL,
  p0 = 0,
  model = c("two_component", "fitness_only"),
  days = 100,
  same_day_load = c("exclude", "include")
)
```

## Arguments

- load:

  Daily training load, a single finite number `> 0`, done every day from
  day 1.

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

- days:

  Last day of the curve, a single whole number `>= 1`.

- same_day_load:

  Timing convention: `"exclude"` (the default) or `"include"`. See the
  section on the timing convention.

## Value

A list of class `"constant_training"` with the elements

- `curve`: a data frame with the columns `day` (1 to `days`), `fitness`,
  `fatigue` (`NA` for the fitness-only model) and `predicted`;

- `asymptote`: predicted performance as days grow;

- `time_of_minimum`: day of poorest performance, or `NA`;

- `load`, `model`, `same_day_load`, `days` and `parameters`: the
  arguments used.

## Formula

For a daily load \\T\\ and the time constant \\\tau\\ of either
component, \$\$g\_{inc}(t) = T\\\frac{1 - e^{-t/\tau}}{1 - e^{-1/\tau}},
\qquad g\_{exc}(t) = T\\e^{-1/\tau}\\\frac{1 - e^{-(t-1)/\tau}}{1 -
e^{-1/\tau}}\$\$ under `same_day_load = "include"` and `"exclude"` (the
default, D-012). These equal
[`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md)
on a series of constant load.

## Asymptote

The asymptote is the predicted performance as days grow. It depends on
the convention: since \\g\_{exc}(t) = g\_{inc}(t) - T\\, the "exclude"
asymptote is the "include" one minus \\(k_1 - k_2)\\T\\:
\$\$p\_{inc}(\infty) = p_0 + \frac{k_1 T}{1 - e^{-1/\tau_1}} - \frac{k_2
T}{1 - e^{-1/\tau_2}}, \qquad p\_{exc}(\infty) = p_0 + \frac{k_1 T
e^{-1/\tau_1}}{1 - e^{-1/\tau_1}} - \frac{k_2 T e^{-1/\tau_2}}{1 -
e^{-1/\tau_2}}.\$\$

## Time of minimum

The day of poorest performance (Morton et al. 1990, Eq. 10; their
\\t_n\\, named in words here, D-026) is \$\$\mathrm{time\\of\\minimum} =
\frac{\tau_1 \tau_2}{\tau_1 - \tau_2} \ln\frac{\tau_1 k_2 (1 -
e^{-1/\tau_1})}{\tau_2 k_1 (1 - e^{-1/\tau_2})},\$\$ the same under both
conventions. It is a continuous time: the day with the lowest predicted
value in `curve` is the nearest whole day.

`time_of_minimum` is `NA` when there is no minimum: when \\\tau_1 \le
\tau_2\\, when the argument of the logarithm is \\\le 1\\ (fatigue is
too small for performance to dip), when \\k_1 = 0\\ (performance only
falls), and for the fitness-only model (performance only rises).

## References

Morton RH, Fitz-Clarke JR, Banister EW (1990). Modeling human
performance in running. *Journal of Applied Physiology*, 69(3),
1171-1177.

## See also

[`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md),
[`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md),
[`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md).

## Examples

``` r
# Morton et al. (1990): load 100 every day
constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                  same_day_load = "include")
#> <constant_training> Constant daily training of 100: two-component model
#> Timing convention: same_day_load = "include" (a day's load counts on the same day)
#> Parameters: p0 = 0, k1 = 1, k2 = 2
#> Time constants: tau1 = 45 days (half-life 31.19 days), tau2 = 15 days (half-life 10.4 days)
#> Asymptote of predicted performance: 1449.07
#> Time of minimum: 16.09 days
#> Curve: days 1 to 100 in $curve.
```
