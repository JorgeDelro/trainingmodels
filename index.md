# trainingmodels

`trainingmodels` provides mathematical models of training load and
training response used in sport science. The package is
**experimental**: its interface may still change.

Version 0.0.3 contains:

- [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md):
  builds a complete daily calendar of training load from session data,
  for one or several athletes;
- [`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md):
  session RPE load (RPE x duration; Foster 1998, Foster et al. 2001);
- [`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md):
  rolling sum and mean of the daily load over a window;
- [`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md):
  Foster’s training monotony and strain over a rolling window;
- [`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md):
  simulation of the Banister impulse-response model (two-component or
  fitness-only) from parameters given by the user;
- [`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md)
  and
  [`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md):
  response to a single session and to constant daily training;
- [`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  and
  [`time_constant()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md):
  conversion between time constants and half-lives.

The Banister model is simulated, not fitted: estimating its parameters
from data is planned for version 0.1.0. Acute:chronic workload ratios
and EWMA-based loads are in the
[ACWR](https://CRAN.R-project.org/package=ACWR) package, not here.

## Example

The week of Foster (1998, Table 1):

``` r

library(trainingmodels)
load <- srpe_load(c(5, 7, 2, 6, 7, 2, 7), c(180, 120, 20, 90, 75, 20, 120))
week <- data.frame(date = as.Date("2026-01-04") + 0:6, load = load)
x <- as_daily_load(week, date = "date", load = "load")
monotony_strain(x)
```

On the seventh day the weekly load is 3725, the monotony 1.45 and the
strain 5397.

The example of Morton et al. (1990): load 100 every day for 60 days,
then rest.

``` r

x <- as_daily_load(
  data.frame(date = as.Date("2026-01-01") + 0:119,
             load = c(rep(100, 60), rep(0, 60))),
  date = "date", load = "load"
)
sim <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                         same_day_load = "include")
which.min(sim$predicted)
session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
```

Predicted performance is lowest on day 16; one session lowers
performance for about 16 days and raises it most after about 40 days.

Design decisions are recorded in
[DECISIONS.md](https://jorgedelro.github.io/trainingmodels/DECISIONS.md),
formulas and their verification in
[MODELS.md](https://jorgedelro.github.io/trainingmodels/MODELS.md), and
the use of AI assistance is disclosed in
[AI_USAGE.md](https://jorgedelro.github.io/trainingmodels/AI_USAGE.md).

## Installation

The development version can be installed with:

``` r

# install.packages("pak")
pak::pak("JorgeDelro/trainingmodels")
```

## Contributing

See
[CONTRIBUTING.md](https://jorgedelro.github.io/trainingmodels/CONTRIBUTING.md).

## Code of Conduct

Please note that the trainingmodels project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
