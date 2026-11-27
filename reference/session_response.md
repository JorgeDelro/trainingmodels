# Response to a single training session

Computes the effect on predicted performance of one unit of load on the
days after a single session (the influence curve), the time until that
effect becomes positive and the time until it is largest (MODELS.md,
M-05). Nothing is fitted: the parameters are given by the user.

## Usage

``` r
session_response(
  k1,
  tau1,
  k2 = NULL,
  tau2 = NULL,
  model = c("two_component", "fitness_only"),
  days = 60,
  same_day_load = c("exclude", "include")
)
```

## Arguments

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

- model:

  `"two_component"` (the default; fitness and fatigue) or
  `"fitness_only"` (D-023).

- days:

  Last day of the curve, a single whole number `>= 1`. The curve runs
  from day 0 (the day of the session) to `days`.

- same_day_load:

  Timing convention: `"exclude"` (the default) or `"include"`. See the
  section on the timing convention.

## Value

A list of class `"session_response"` with the elements

- `curve`: a data frame with the columns `day` (0 to `days`) and
  `effect` (effect on predicted performance per unit of load);

- `time_to_recover`, `time_to_peak` (days) and `peak_effect` (per unit
  of load), each a number or `NA`;

- `model`, `same_day_load`, `days` and `parameters`: the arguments used.

## Formula

The effect \\u\\ days after one unit of load is \$\$L(u) =
k_1\\e^{-u/\tau_1} - k_2\\e^{-u/\tau_2}\$\$ for the two-component model,
and \\k_1\\e^{-u/\tau_1}\\ for the fitness-only model. For \\\tau_1 \>
\tau_2\\, \$\$\mathrm{time\\to\\recover} = \frac{\tau_1 \tau_2}{\tau_1 -
\tau_2} \ln\frac{k_2}{k_1}, \qquad \mathrm{time\\to\\peak} =
\frac{\tau_1 \tau_2}{\tau_1 - \tau_2} \ln\frac{k_2 \tau_1}{k_1
\tau_2},\$\$ and `peak_effect` is \\L\\ at `time_to_peak`. These are
\\t_n\\ and \\t_g\\ of Clarke & Skiba (2013) and Busso & Chalencon
(2023); they are named in words because Morton et al. (1990) use \\t_n\\
for a different quantity, the `time_of_minimum` of
[`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md)
(DECISIONS.md, D-026).

## Timing convention

The times do not depend on the convention. Only the effect on the day of
the session (day 0 of `curve`) does: \\k_1 - k_2\\ with
`same_day_load = "include"`, 0 with `"exclude"` (the default, D-012).
From day 1 on, both conventions give \\L(u)\\.

## When the times are NA

The times are `NA` when they do not exist (D-026):

- `time_to_recover` is `NA` when \\k_2 \le k_1\\: the effect is positive
  from the first day after the session, so there is nothing to recover
  from.

- `time_to_peak` and `peak_effect` are `NA` when \\k_2 \tau_1 \le k_1
  \tau_2\\: the effect is largest right after the session and only
  decreases.

- Both are `NA` when \\k_1 = 0\\ (the effect is never positive), when
  \\\tau_1 \le \tau_2\\ (fatigue does not fade faster than fitness), and
  for the fitness-only model (there is no fatigue).

## References

Clarke DC, Skiba PF (2013). Rationale and resources for teaching the
mathematical modeling of athletic training and performance. *Advances in
Physiology Education*, 37, 134-152.

Busso T, Chalencon S (2023). Validity and accuracy of impulse-response
models for modeling and predicting training effects on performance of
swimmers. *Medicine & Science in Sports & Exercise*, 55(7), 1274-1285.

Ceddia D, Bondell H, Taylor P (2025). Mathematical modelling and
optimisation of athletic performance: tapering and periodisation.
arXiv:2505.20859 (preprint).

## See also

[`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md),
[`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md),
[`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md).

## Examples

``` r
# Parameters of Morton et al. (1990)
r <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
r
#> <session_response> Response to a single session: two-component model
#> Timing convention: same_day_load = "exclude" (a day's load affects performance from the next day)
#> Parameters: k1 = 1, k2 = 2
#> Time constants: tau1 = 45 days (half-life 31.19 days), tau2 = 15 days (half-life 10.4 days)
#> Time to recover: 15.6 days
#> Time to peak: 40.31 days (effect 0.2722 per unit of load)
#> Curve: days 0 to 60 in $curve; day 0 is the day of the session.
head(r$curve)
#>   day     effect
#> 1   0  0.0000000
#> 2   1 -0.8929911
#> 3   2 -0.7938179
#> 4   3 -0.7019545
#> 5   4 -0.6169094
#> 6   5 -0.5382233

# Fit of Clarke & Skiba (2013)
session_response(k1 = 0.18258, tau1 = 35.821, k2 = 0.23016, tau2 = 21.340)
#> <session_response> Response to a single session: two-component model
#> Timing convention: same_day_load = "exclude" (a day's load affects performance from the next day)
#> Parameters: k1 = 0.1826, k2 = 0.2302
#> Time constants: tau1 = 35.82 days (half-life 24.83 days), tau2 = 21.34 days (half-life 14.79 days)
#> Time to recover: 12.22 days
#> Time to peak: 39.57 days (effect 0.02446 per unit of load)
#> Curve: days 0 to 60 in $curve; day 0 is the day of the session.
```
