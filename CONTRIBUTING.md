# Contributing to trainingmodels

Thank you for your interest in contributing. The package is in early
development, so please open an issue before starting any work.

## Reporting bugs

Open an issue using the **Bug report** template. Include a minimal
reproducible example (for instance with the
[reprex](https://reprex.tidyverse.org/) package) and the output of
`sessionInfo()`.

## Proposing a new method

Open an issue using the **New method proposal** template. Every proposal must
give the primary reference in which the formula was published. Methods are
only implemented after the formula has been verified against that source.

## Pull requests

* Link the pull request to an existing issue.
* Write code from the verified formula. Third-party code may be used as an
  external reference for tests, but must never be copied into the package.
* Document the formula, its source and its limitations with roxygen2
  (markdown syntax).
* Add tests with testthat (3rd edition), including at least one numerical test
  against a published or reference value.
* Make sure `devtools::check()` passes with 0 errors and 0 warnings.
* Disclose any AI assistance in the pull request description.
* Code, documentation and commit messages are written in English.

## Code of Conduct

Please note that this project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
