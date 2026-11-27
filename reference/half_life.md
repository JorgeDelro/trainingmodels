# Convert between time constants and half-lives

`half_life()` gives the number of days for a component to fall to half,
\\\tau \ln 2\\, and `time_constant()` gives the time constant \\\tau\\
of a half-life (MODELS.md, Notation).

## Usage

``` r
half_life(tau)

time_constant(half_life)
```

## Arguments

- tau:

  Time constants in days: a numeric vector of positive finite numbers.

- half_life:

  Half-lives in days: a numeric vector of positive finite numbers.

## Value

A numeric vector of the same length.

## Details

Impulse-response functions take time constants, never half-lives; print
methods show the half-life next to each time constant (DECISIONS.md,
D-024).

## See also

[`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md),
[`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md).

## Examples

``` r
half_life(c(45, 15))
#> [1] 31.19162 10.39721
time_constant(7)
#> [1] 10.09887
```
