# trainingmodels

`trainingmodels` provides mathematical models of training load and
training response used in sport science. The package is
**experimental**: its interface may still change.

Version 0.0.2 contains:

- [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md):
  builds a complete daily calendar of training load from session data,
  for one or several athletes;
- [`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md):
  session RPE load (RPE x duration; Foster 1998, Foster et al. 2001);
- [`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md):
  rolling sum and mean of the daily load over a window;
- [`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md):
  Foster’s training monotony and strain over a rolling window.

Impulse-response models (starting with the Banister model) are not
implemented yet. Acute:chronic workload ratios and EWMA-based loads are
in the [ACWR](https://CRAN.R-project.org/package=ACWR) package, not
here.

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
