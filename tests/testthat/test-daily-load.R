# Tests for as_daily_load() and its methods (DECISIONS.md, D-015 to D-017).
# Every expected value is written as a literal that can be checked by hand
# against the small inline data frame of the test.

# Silences the "filled days" message in tests that do not check it.
quiet_daily_load <- function(...) suppressMessages(as_daily_load(...))

d <- function(x) as.Date(x)

# 1. Same-day sessions --------------------------------------------------------

test_that("same-day sessions are summed and n_sessions counts rows", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-01", "2026-01-01", "2026-01-02")),
    load = c(100, 50, 25, 40)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")

  expect_equal(out$date, d(c("2026-01-01", "2026-01-02")))
  expect_equal(out$load, c(175, 40))
  expect_identical(out$n_sessions, c(3L, 1L))
  expect_identical(as.character(out$status), c("training", "training"))
  expect_identical(out$filled, c(FALSE, FALSE))
})

# 2. Days without a row are rest by default ----------------------------------

test_that("days without a row are filled as rest with a message", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-04")),
    load = c(100, 80)
  )
  expect_message(
    out <- as_daily_load(x, date = "date", load = "load"),
    "2 days"
  )

  expect_equal(
    out$date,
    d(c("2026-01-01", "2026-01-02", "2026-01-03", "2026-01-04"))
  )
  expect_equal(out$load, c(100, 0, 0, 80))
  expect_identical(
    as.character(out$status),
    c("training", "rest", "rest", "training")
  )
  expect_identical(out$n_sessions, c(1L, 0L, 0L, 1L))
  expect_identical(out$filled, c(FALSE, TRUE, TRUE, FALSE))
  expect_identical(attr(out, "gaps"), "rest")
})

test_that("no message is given when no day is filled", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")), load = c(10, 20))
  expect_no_message(as_daily_load(x, date = "date", load = "load"))
})

# 3. gaps = "missing" ---------------------------------------------------------

test_that("gaps = 'missing' fills days without a row with NA and 'missing'", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-04")),
    load = c(100, 80)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", gaps = "missing")

  expect_equal(out$load, c(100, NA, NA, 80))
  expect_identical(
    as.character(out$status),
    c("training", "missing", "missing", "training")
  )
  expect_identical(out$n_sessions, c(1L, 0L, 0L, 1L))
  expect_identical(out$filled, c(FALSE, TRUE, TRUE, FALSE))
  expect_identical(attr(out, "gaps"), "missing")
})

# 4. NA loads -----------------------------------------------------------------

test_that("a row with NA load gives status 'missing'", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-02", "2026-01-03")),
    load = c(100, NA, 60)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")

  expect_equal(out$load, c(100, NA, 60))
  expect_identical(
    as.character(out$status),
    c("training", "missing", "training")
  )
  expect_identical(out$n_sessions, c(1L, 1L, 1L))
  expect_identical(out$filled, c(FALSE, FALSE, FALSE))
})

test_that("a day with one NA session and one non-NA session is 'missing'", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-02", "2026-01-02")),
    load = c(100, NA, 30)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")

  expect_equal(out$load, c(100, NA))
  expect_identical(as.character(out$status), c("training", "missing"))
  expect_identical(out$n_sessions, c(1L, 2L))
  expect_identical(out$filled, c(FALSE, FALSE))
})

# 5. Zero loads ---------------------------------------------------------------

test_that("a row with load 0 gives status 'rest' and filled FALSE", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-02", "2026-01-03")),
    load = c(100, 0, 60)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")

  expect_equal(out$load, c(100, 0, 60))
  expect_identical(
    as.character(out$status),
    c("training", "rest", "training")
  )
  expect_identical(out$n_sessions, c(1L, 1L, 1L))
  expect_identical(out$filled, c(FALSE, FALSE, FALSE))
})

# 6. Long runs of filled days -------------------------------------------------

test_that("7 consecutive filled days give no warning", {
  # 2026-01-02 to 2026-01-08 are filled: 7 days.
  x <- data.frame(date = d(c("2026-01-01", "2026-01-09")), load = c(10, 10))
  expect_no_warning(
    out <- quiet_daily_load(x, date = "date", load = "load")
  )
  expect_identical(sum(out$filled), 7L)
})

test_that("8 consecutive filled days give a warning naming athlete and dates", {
  # 2026-01-02 to 2026-01-09 are filled: 8 days.
  x <- data.frame(date = d(c("2026-01-01", "2026-01-10")), load = c(10, 10))
  expect_warning(
    out <- quiet_daily_load(x, date = "date", load = "load"),
    "2026-01-02.*2026-01-09"
  )
  expect_warning(
    quiet_daily_load(x, date = "date", load = "load"),
    "athlete 1",
    ignore.case = TRUE
  )
  expect_identical(sum(out$filled), 8L)
})

test_that("max_gap sets the warning threshold", {
  # 2026-01-02 to 2026-01-05 are filled: 4 days.
  x <- data.frame(date = d(c("2026-01-01", "2026-01-06")), load = c(10, 10))
  expect_no_warning(
    quiet_daily_load(x, date = "date", load = "load", max_gap = 4)
  )
  expect_warning(
    quiet_daily_load(x, date = "date", load = "load", max_gap = 3),
    "2026-01-02.*2026-01-05"
  )
})

test_that("the long-gap warning is also given under gaps = 'missing'", {
  # 2026-01-02 to 2026-01-09 have no row: 8 days.
  x <- data.frame(date = d(c("2026-01-01", "2026-01-10")), load = c(10, 10))
  expect_warning(
    out <- quiet_daily_load(x, date = "date", load = "load", gaps = "missing"),
    "2026-01-02.*2026-01-09"
  )
  expect_warning(
    quiet_daily_load(x, date = "date", load = "load", gaps = "missing"),
    "athlete 1",
    ignore.case = TRUE
  )
  expect_identical(sum(out$filled), 8L)
})

# 7. Several athletes ---------------------------------------------------------

test_that("two athletes get separate calendars", {
  x <- data.frame(
    id = c("A", "A", "B", "B"),
    date = d(c("2026-01-01", "2026-01-03", "2026-01-02", "2026-01-04")),
    load = c(10, 30, 20, 40)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", athlete = "id")

  expect_identical(out$athlete, c("A", "A", "A", "B", "B", "B"))
  expect_equal(
    out$date,
    d(c(
      "2026-01-01", "2026-01-02", "2026-01-03",
      "2026-01-02", "2026-01-03", "2026-01-04"
    ))
  )
  expect_equal(out$load, c(10, 0, 30, 20, 0, 40))
  expect_identical(out$filled, c(FALSE, TRUE, FALSE, FALSE, TRUE, FALSE))
})

test_that("without an athlete column the single athlete is labelled '1'", {
  x <- data.frame(date = d("2026-01-01"), load = 10)
  out <- quiet_daily_load(x, date = "date", load = "load")
  expect_identical(out$athlete, "1")
})

test_that("a numeric athlete column is returned as character", {
  x <- data.frame(id = c(7, 7), date = d(c("2026-01-01", "2026-01-02")),
                  load = c(10, 20))
  out <- quiet_daily_load(x, date = "date", load = "load", athlete = "id")
  expect_identical(out$athlete, c("7", "7"))
})

test_that("one of several load columns is used and its name is stored", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-02")),
    srpe = c(300, 400),
    distance = c(5, 8)
  )
  out <- quiet_daily_load(x, date = "date", load = "srpe")
  expect_equal(out$load, c(300, 400))
  expect_identical(attr(out, "load_name"), "srpe")
  expect_false("distance" %in% names(out))
})

# 8. Errors -------------------------------------------------------------------

test_that("negative load is an error", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")), load = c(10, -5))
  expect_error(as_daily_load(x, date = "date", load = "load"), "negative")
})

test_that("non-finite load (Inf, NaN) is an error", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")), load = c(10, Inf))
  expect_error(as_daily_load(x, date = "date", load = "load"), "finite")
  x$load <- c(10, NaN)
  expect_error(as_daily_load(x, date = "date", load = "load"), "finite")
})

test_that("non-numeric load is an error", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")),
                  load = c("10", "20"))
  expect_error(as_daily_load(x, date = "date", load = "load"), "numeric")
})

test_that("an empty (all-NA logical) load column gives every day 'missing'", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02", "2026-01-03")),
                  load = c(NA, NA, NA))
  out <- quiet_daily_load(x, date = "date", load = "load")
  expect_type(out$load, "double")
  expect_equal(out$load, c(NA_real_, NA_real_, NA_real_))
  expect_identical(
    as.character(out$status),
    c("missing", "missing", "missing")
  )
})

test_that("an empty (all-NA logical) performance column gives all NA", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")), load = c(10, 20),
                  perf = c(NA, NA))
  out <- quiet_daily_load(x, date = "date", load = "load", performance = "perf")
  expect_type(out$performance, "double")
  expect_equal(out$performance, c(NA_real_, NA_real_))
})

test_that("a logical column with TRUE or FALSE is an error", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")),
                  load = c(TRUE, NA), perf = c(NA, FALSE))
  expect_error(as_daily_load(x, date = "date", load = "load"), "numeric")
  x$load <- c(10, 20)
  expect_error(
    as_daily_load(x, date = "date", load = "load", performance = "perf"),
    "numeric"
  )
})

test_that("an unparseable date is an error naming the first offending row", {
  x <- data.frame(
    date = c("2026-01-01", "2026/01/02", "not a date"),
    load = c(10, 20, 30)
  )
  expect_error(as_daily_load(x, date = "date", load = "load"), "row 2")
})

test_that("a POSIXct date is an error telling the user to convert to Date", {
  x <- data.frame(
    date = as.POSIXct(c("2026-01-01 10:00", "2026-01-02 10:00"), tz = "UTC"),
    load = c(10, 20)
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load"),
    "POSIXct.*Date|Date.*POSIXct"
  )
})

test_that("a named column that is not in data is an error naming it", {
  x <- data.frame(date = d("2026-01-01"), load = 10, perf = 1, id = "A")
  expect_error(as_daily_load(x, date = "day", load = "load"), "day")
  expect_error(as_daily_load(x, date = "date", load = "srpe"), "srpe")
  expect_error(
    as_daily_load(x, date = "date", load = "load", athlete = "player"),
    "player"
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", performance = "time"),
    "time"
  )
})

test_that("NA in the athlete column is an error", {
  x <- data.frame(id = c("A", NA), date = d(c("2026-01-01", "2026-01-02")),
                  load = c(10, 20))
  expect_error(
    as_daily_load(x, date = "date", load = "load", athlete = "id"),
    "id|athlete"
  )
})

test_that("NA in the date column is an error", {
  x <- data.frame(date = d(c("2026-01-01", NA)), load = c(10, 20))
  expect_error(as_daily_load(x, date = "date", load = "load"), "NA|missing")
})

test_that("two different performance values on one athlete-day is an error", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-01")),
    load = c(10, 20),
    perf = c(50, 51)
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", performance = "perf"),
    "performance|perf"
  )
})

test_that("non-numeric performance is an error", {
  x <- data.frame(date = d("2026-01-01"), load = 10, perf = "fast")
  expect_error(
    as_daily_load(x, date = "date", load = "load", performance = "perf"),
    "numeric"
  )
})

test_that("zero rows is an error", {
  x <- data.frame(date = as.Date(character()), load = numeric())
  expect_error(as_daily_load(x, date = "date", load = "load"), "rows")
})

test_that("invalid gaps, max_gap and date_format are errors", {
  x <- data.frame(date = d(c("2026-01-01", "2026-01-02")), load = c(10, 20))
  expect_error(
    as_daily_load(x, date = "date", load = "load", gaps = "zero"),
    "gaps"
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", max_gap = -1),
    "max_gap"
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", max_gap = c(3, 4)),
    "max_gap"
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", max_gap = "7"),
    "max_gap"
  )
  y <- data.frame(date = c("2026-01-01", "2026-01-02"), load = c(10, 20))
  expect_error(
    as_daily_load(y, date = "date", load = "load",
                  date_format = c("%Y-%m-%d", "%d/%m/%Y")),
    "date_format"
  )
  expect_error(
    as_daily_load(y, date = "date", load = "load", date_format = 1),
    "date_format"
  )
})

# 9. Date parsing -------------------------------------------------------------

test_that("character dates in ISO format are parsed", {
  x <- data.frame(date = c("2026-01-01", "2026-01-02"), load = c(10, 20))
  out <- quiet_daily_load(x, date = "date", load = "load")
  expect_s3_class(out$date, "Date")
  expect_equal(out$date, d(c("2026-01-01", "2026-01-02")))
})

test_that("date_format = '%d/%m/%Y' parses '03/04/2026' as 3 April 2026", {
  x <- data.frame(date = c("03/04/2026", "04/04/2026"), load = c(10, 20))
  out <- quiet_daily_load(x, date = "date", load = "load",
                          date_format = "%d/%m/%Y")
  expect_equal(out$date, d(c("2026-04-03", "2026-04-04")))
})

test_that("a parsed year before 1900 or after 2100 is an error", {
  # Base R parses "03/04/26" with "%Y" as the year 26.
  x <- data.frame(date = c("03/04/2026", "03/04/26"), load = c(10, 20))
  expect_error(
    as_daily_load(x, date = "date", load = "load", date_format = "%d/%m/%Y"),
    "row 2"
  )
  expect_error(
    as_daily_load(x, date = "date", load = "load", date_format = "%d/%m/%Y"),
    "0026-04-03"
  )
  y <- data.frame(date = c("2026-01-01", "2101-01-01"), load = c(10, 20))
  expect_error(as_daily_load(y, date = "date", load = "load"), "row 2")
  y$date <- c("1899-12-31", "2026-01-01")
  expect_error(as_daily_load(y, date = "date", load = "load"), "row 1")
})

test_that("dates without zero padding are accepted with '%d/%m/%Y'", {
  x <- data.frame(date = "3/4/2026", load = 10)
  out <- quiet_daily_load(x, date = "date", load = "load",
                          date_format = "%d/%m/%Y")
  expect_equal(out$date, d("2026-04-03"))
})

test_that("Date values with a fractional part are floored to the day", {
  x <- data.frame(
    date = as.Date("2026-01-01") + c(0.25, 0.75),
    load = c(10, 20)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")
  expect_equal(unclass(out$date), unclass(d("2026-01-01")))
  expect_equal(out$load, 30)
  expect_identical(out$n_sessions, 2L)
})

# 10. Performance -------------------------------------------------------------

test_that("performance is carried to its day and is NA elsewhere", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-03", "2026-01-04")),
    load = c(10, 30, 40),
    perf = c(NA, 55, NA)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", performance = "perf")
  expect_equal(out$performance, c(NA, NA, 55, NA))
})

test_that("identical repeated performance values on one day are accepted", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-01", "2026-01-02")),
    load = c(10, 20, 30),
    perf = c(50, 50, NA)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", performance = "perf")
  expect_equal(out$performance, c(50, NA))
  expect_equal(out$load, c(30, 30))
})

test_that("one NA and one non-NA performance on one day give the non-NA", {
  x <- data.frame(
    date = d(c("2026-01-01", "2026-01-01")),
    load = c(10, 20),
    perf = c(NA, 50)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", performance = "perf")
  expect_equal(out$performance, 50)
})

# 11. Invariants --------------------------------------------------------------

test_that("output has the specified class, columns, types and attributes", {
  x <- data.frame(
    date = d(c("2026-01-02", "2026-01-01")),
    load = c(10, 20)
  )
  out <- quiet_daily_load(x, date = "date", load = "load")
  expect_identical(class(out), c("daily_load", "data.frame"))
  expect_identical(
    names(out),
    c("athlete", "date", "load", "status", "n_sessions", "filled")
  )
  expect_type(out$athlete, "character")
  expect_s3_class(out$date, "Date")
  expect_type(out$load, "double")
  expect_s3_class(out$status, "factor")
  expect_identical(levels(out$status), c("training", "rest", "missing"))
  expect_type(out$n_sessions, "integer")
  expect_type(out$filled, "logical")
  expect_identical(attr(out, "gaps"), "rest")
  expect_identical(attr(out, "load_name"), "load")

  out_p <- quiet_daily_load(cbind(x, perf = c(1, 2)), date = "date",
                            load = "load", performance = "perf")
  expect_identical(
    names(out_p),
    c("athlete", "date", "load", "status", "n_sessions", "filled",
      "performance")
  )
  expect_type(out_p$performance, "double")
})

test_that("one row per athlete-day, consecutive dates, sorted", {
  # Rows deliberately unsorted, with repeats and gaps.
  x <- data.frame(
    id = c("B", "A", "B", "A", "A", "B"),
    date = d(c(
      "2026-01-05", "2026-01-03", "2026-01-02",
      "2026-01-01", "2026-01-03", "2026-01-02"
    )),
    load = c(5, 3, 2, 1, 3, 2)
  )
  out <- quiet_daily_load(x, date = "date", load = "load", athlete = "id")

  expect_identical(out$athlete, c("A", "A", "A", "B", "B", "B", "B"))
  expect_equal(
    out$date,
    d(c(
      "2026-01-01", "2026-01-02", "2026-01-03",
      "2026-01-02", "2026-01-03", "2026-01-04", "2026-01-05"
    ))
  )
  expect_equal(out$load, c(1, 0, 6, 4, 0, 0, 5))
  expect_identical(out$n_sessions, c(1L, 0L, 2L, 2L, 0L, 0L, 1L))

  key <- paste(out$athlete, out$date)
  expect_false(anyDuplicated(key) > 0)
  for (a in unique(out$athlete)) {
    expect_true(all(diff(out$date[out$athlete == a]) == 1))
  }
})

# 12. print() and summary() ---------------------------------------------------

summary_data <- function() {
  data.frame(
    id = c("A", "A", "A", "A", "B", "B"),
    date = d(c(
      "2026-01-01", "2026-01-01", "2026-01-02", "2026-01-05",
      "2026-02-10", "2026-02-11"
    )),
    load = c(100, 50, 0, NA, 30, 40),
    perf = c(50, NA, NA, 52, NA, 60)
  )
}

test_that("print() runs and returns the object invisibly", {
  out <- quiet_daily_load(summary_data(), date = "date", load = "load",
                          athlete = "id", performance = "perf")
  expect_output(res <- withVisible(print(out)))
  expect_false(res$visible)
  expect_identical(res$value, out)
})

test_that("summary() returns one row per athlete with the specified counts", {
  # A: 01-01 training (150), 01-02 rest (row), 01-03 and 01-04 filled rest,
  #    01-05 missing (NA row). Performance on 01-01 and 01-05.
  # B: 02-10 and 02-11 training. Performance on 02-11.
  out <- quiet_daily_load(summary_data(), date = "date", load = "load",
                          athlete = "id", performance = "perf")
  s <- summary(out)

  expect_s3_class(s, "data.frame")
  expect_identical(
    names(s),
    c("athlete", "first_date", "last_date", "n_days", "n_training", "n_rest",
      "n_missing", "n_filled", "longest_filled_run", "n_performance")
  )
  expect_identical(s$athlete, c("A", "B"))
  expect_equal(s$first_date, d(c("2026-01-01", "2026-02-10")))
  expect_equal(s$last_date, d(c("2026-01-05", "2026-02-11")))
  expect_equal(s$n_days, c(5, 2))
  expect_equal(s$n_training, c(1, 2))
  expect_equal(s$n_rest, c(3, 0))
  expect_equal(s$n_missing, c(1, 0))
  expect_equal(s$n_filled, c(2, 0))
  expect_equal(s$longest_filled_run, c(2, 0))
  expect_equal(s$n_performance, c(2, 1))
})

test_that("summary() counts filled days as missing under gaps = 'missing'", {
  out <- quiet_daily_load(summary_data(), date = "date", load = "load",
                          athlete = "id", gaps = "missing")
  s <- summary(out)
  expect_equal(s$n_rest, c(1, 0))
  expect_equal(s$n_missing, c(3, 0))
  expect_equal(s$n_filled, c(2, 0))
  expect_equal(s$n_performance, c(0, 0))
})
