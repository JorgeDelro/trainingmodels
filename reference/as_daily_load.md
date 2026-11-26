# Build a daily training-load series

Converts a data frame with one row per training session (or per day)
into a complete daily calendar with one row per athlete and day. This is
the single entry point for every analysis in the package: descriptors
and impulse-response models take a `daily_load` object.

## Usage

``` r
as_daily_load(
  data,
  date,
  load,
  athlete = NULL,
  performance = NULL,
  gaps = c("rest", "missing"),
  max_gap = 7,
  date_format = NULL
)
```

## Arguments

- data:

  A data frame with one row per session (or per day).

- date:

  Name of the date column. The column must be of class `Date`, or
  character to be parsed with `date_format`. A `Date` with a fraction of
  a day is floored to the day. Date-times (`POSIXct`) are rejected:
  convert them with [`as.Date()`](https://rdrr.io/r/base/as.Date.html)
  first, choosing the time zone.

- load:

  Name of the load column: numeric, `>= 0` or `NA`. A column that is
  entirely `NA` (an empty column in a CSV file, read as logical) is
  accepted as numeric `NA`.

- athlete:

  Name of the athlete identifier column, or `NULL` (the default) for a
  single athlete, who is labelled `"1"`.

- performance:

  Name of a numeric performance column, or `NULL`. At most one distinct
  non-`NA` value is allowed per athlete and day. An entirely `NA` column
  is accepted, as for `load`.

- gaps:

  How to treat days with no row between an athlete's first and last
  date: `"rest"` (load 0, the default) or `"missing"` (load `NA`).

- max_gap:

  A single non-negative whole number. A warning is given for each run of
  more than `max_gap` consecutive days without a row.

- date_format:

  Format used to parse a character date column, as in
  [`strptime()`](https://rdrr.io/r/base/strptime.html). The default
  `NULL` accepts ISO dates (`"%Y-%m-%d"`) only. Any parsed year before
  1900 or after 2100 is an error, which catches two-digit years read
  with `"%Y"`.

## Value

An object of class `c("daily_load", "data.frame")` with one row per
athlete and day, sorted by athlete and date, and the columns:

- `athlete` (character);

- `date` (`Date`), consecutive within each athlete;

- `load` (numeric), the sum of the day's sessions;

- `status` (factor with levels `"training"`, `"rest"`, `"missing"`);

- `n_sessions` (integer), the number of rows in `data` for that day, 0
  for filled days;

- `filled` (logical), `TRUE` for days that had no row;

- `performance` (numeric), only if `performance` was given.

The attributes `gaps` and `load_name` record the gap option used and the
name of the load column.

## Day states

Every day has exactly one of three states (DECISIONS.md, D-015):

- **training**: the load of the day is greater than 0;

- **rest**: the load of the day is 0;

- **missing**: the load of the day is not available (`NA`).

Sessions on the same day are summed. If any session of a day has an `NA`
load, the whole day is `NA` and its state is "missing": a missing load
is never silently replaced (D-016).

## Gap rule

Each athlete's calendar runs from their own first to their own last
date. Days in between that have no row are added and marked
`filled = TRUE`. By default (`gaps = "rest"`) they are treated as rest
days with load 0; with `gaps = "missing"` they get load `NA` and state
"missing" (D-015). The calendar ends at the athlete's last row: rest
days after the last session are not added, so trailing rest days must be
given as rows with load 0 to be included. A message reports how many
days were filled. Whatever `gaps` is, a warning is given for every run
of more than `max_gap` consecutive filled days, because a long run
without data is as likely to be missing data as rest.

## Several athletes and load columns

A data file may hold several athletes (identified by the column named in
`athlete`) and several load columns; each call uses one load column
(D-017). Its name is kept in the attribute `load_name`.

## See also

[`print.daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/print.daily_load.md),
[`summary.daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/summary.daily_load.md).

## Examples

``` r
sessions <- data.frame(
  athlete = c("A", "A", "A", "A", "B", "B"),
  date = c("2026-01-01", "2026-01-01", "2026-01-02", "2026-01-05",
           "2026-01-03", "2026-01-04"),
  srpe = c(300, 150, 0, NA, 420, 380),
  jump = c(41.2, NA, NA, 40.5, NA, 38.9)
)

x <- as_daily_load(sessions, date = "date", load = "srpe",
                   athlete = "athlete", performance = "jump")
#> Filled 2 days without a row as rest (load 0). Use gaps = "missing" to treat filled days as missing.
x
#> <daily_load> 2 athletes, 2026-01-01 to 2026-01-05, 7 days
#> Days: 3 training, 3 rest, 1 missing; 2 filled (as rest)
#> Load column: srpe
#> 
#>   athlete       date load   status n_sessions filled performance
#> 1       A 2026-01-01  450 training          2  FALSE        41.2
#> 2       A 2026-01-02    0     rest          1  FALSE          NA
#> 3       A 2026-01-03    0     rest          0   TRUE          NA
#> 4       A 2026-01-04    0     rest          0   TRUE          NA
#> 5       A 2026-01-05   NA  missing          1  FALSE        40.5
#> 6       B 2026-01-03  420 training          1  FALSE          NA
#> 7       B 2026-01-04  380 training          1  FALSE        38.9
summary(x)
#>   athlete first_date  last_date n_days n_training n_rest n_missing n_filled
#> 1       A 2026-01-01 2026-01-05      5          1      3         1        2
#> 2       B 2026-01-03 2026-01-04      2          2      0         0        0
#>   longest_filled_run n_performance
#> 1                  2             2
#> 2                  0             1

# Days without a row treated as missing instead of rest
as_daily_load(sessions, date = "date", load = "srpe",
              athlete = "athlete", gaps = "missing")
#> Filled 2 days without a row as missing (load NA).
#> <daily_load> 2 athletes, 2026-01-01 to 2026-01-05, 7 days
#> Days: 3 training, 1 rest, 3 missing; 2 filled (as missing)
#> Load column: srpe
#> 
#>   athlete       date load   status n_sessions filled
#> 1       A 2026-01-01  450 training          2  FALSE
#> 2       A 2026-01-02    0     rest          1  FALSE
#> 3       A 2026-01-03   NA  missing          0   TRUE
#> 4       A 2026-01-04   NA  missing          0   TRUE
#> 5       A 2026-01-05   NA  missing          1  FALSE
#> 6       B 2026-01-03  420 training          1  FALSE
#> 7       B 2026-01-04  380 training          1  FALSE
```
