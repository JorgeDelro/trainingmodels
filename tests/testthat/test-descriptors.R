# Tests for srpe_load(), rolling_load() and monotony_strain() (MODELS.md,
# M-10 to M-12; DECISIONS.md, D-020 to D-022, A-011). Every expected value is
# a literal that can be checked by hand, or a value from Foster 1998, Table 1.

# A daily_load with one row per day from `start`, one athlete unless
# `athlete` is given. Every day has a row, so no day is filled.
daily <- function(load, start = "2026-01-04", athlete = NULL) {
  dates <- as.Date(start) + seq_along(load) - 1L
  if (is.null(athlete)) {
    as_daily_load(data.frame(date = dates, load = load),
                  date = "date", load = "load")
  } else {
    as_daily_load(data.frame(id = athlete, date = dates, load = load),
                  date = "date", load = "load", athlete = "id")
  }
}

# Foster 1998, Table 1 (MODELS.md, M-10 and M-12).
foster_duration <- c(180, 120, 20, 90, 75, 20, 120)
foster_rpe <- c(5, 7, 2, 6, 7, 2, 7)
foster_load <- c(900, 840, 40, 540, 525, 40, 840)

# 1. srpe_load() ----------------------------------------------------------------

test_that("srpe_load() reproduces Foster 1998, Table 1", {
  expect_equal(srpe_load(foster_rpe, foster_duration), foster_load)
})

test_that("srpe_load() recycles length-1 arguments and propagates NA", {
  expect_equal(srpe_load(5, c(60, 90)), c(300, 450))
  expect_equal(srpe_load(c(4, 6), 30), c(120, 180))
  expect_equal(srpe_load(c(5, NA, 7), c(60, 60, NA)), c(300, NA, NA))
  expect_equal(srpe_load(c(0, 10), c(60, 0)), c(0, 0))
})

test_that("srpe_load() rejects rpe outside 0-10, naming the position", {
  expect_error(srpe_load(c(5, 11), c(60, 60)), "position 2")
  expect_error(srpe_load(c(-1, 5), c(60, 60)), "position 1")
})

test_that("srpe_load() rejects a negative or non-finite duration", {
  expect_error(srpe_load(c(5, 5, 5), c(60, 30, -10)), "position 3")
  expect_error(srpe_load(5, Inf), "position 1")
  expect_error(srpe_load(NaN, 60), "position 1")
})

test_that("srpe_load() rejects unequal lengths and non-numeric input", {
  expect_error(srpe_load(c(5, 6), c(60, 60, 60)), "length")
  expect_error(srpe_load("5", 60), "numeric")
  expect_error(srpe_load(5, "60"), "numeric")
  expect_error(srpe_load(factor(5), 60), "numeric")
})

# 2. rolling_load(): definition (M-11) -----------------------------------------

test_that("rolling_load() 'include' sums the window ending on the day", {
  out <- rolling_load(daily(1:5), window = 3, same_day_load = "include")
  expect_equal(out$rolling_sum, c(NA, NA, 6, 9, 12))
  expect_equal(out$rolling_mean, c(NA, NA, 6, 9, 12) / 3)
})

test_that("rolling_load() 'exclude' sums the window ending the day before", {
  out <- rolling_load(daily(1:5), window = 3, same_day_load = "exclude")
  expect_equal(out$rolling_sum, c(NA, NA, NA, 6, 9))
  expect_equal(out$rolling_mean, c(NA, NA, NA, 6, 9) / 3)
})

test_that("rolling_load() defaults to window 7 and 'include'", {
  x <- daily(c(1:10))
  expect_equal(rolling_load(x),
               rolling_load(x, window = 7, same_day_load = "include"))
  expect_identical(attr(rolling_load(x), "same_day_load"), "include")
})

# 3. monotony_strain(): Foster 1998, Table 1 (M-12) ---------------------------

test_that("monotony_strain() reproduces Foster 1998, Table 1 on day 7", {
  out <- monotony_strain(daily(foster_load, start = "2026-01-04"))

  expect_equal(out$date[7], as.Date("2026-01-10"))
  expect_equal(out$window_load[7], 3725, tolerance = 1e-4)
  expect_equal(out$mean_load[7], 532.142857, tolerance = 1e-4)
  expect_equal(out$sd_load[7], 367.285733, tolerance = 1e-4)
  expect_equal(out$monotony[7], 1.448853, tolerance = 1e-4)
  expect_equal(out$strain[7], 5396.9756, tolerance = 1e-4)

  for (col in c("window_load", "mean_load", "sd_load", "monotony", "strain")) {
    expect_true(all(is.na(out[[col]][1:6])), label = col)
  }
})

test_that("monotony_strain() gives the values printed by Foster 1998", {
  out <- monotony_strain(daily(foster_load))
  expect_equal(round(out$mean_load[7]), 532)
  expect_equal(round(out$sd_load[7]), 367)
  expect_equal(round(out$strain[7]), 5397)
  # Foster prints the monotony truncated (MODELS.md, discrepancy log #17).
  expect_equal(floor(out$monotony[7] * 100) / 100, 1.44)
})

test_that("'exclude' on day 8 equals 'include' on day 7 (Foster week)", {
  x <- daily(c(foster_load, 0))
  inc <- monotony_strain(x, same_day_load = "include")
  exc <- monotony_strain(x, same_day_load = "exclude")
  cols <- c("window_load", "mean_load", "sd_load", "monotony", "strain")
  expect_equal(unlist(exc[8, cols]), unlist(inc[7, cols]))
  expect_true(all(is.na(unlist(exc[1:7, cols]))))
})

test_that("monotony_strain() defaults to window 7 and 'include'", {
  x <- daily(c(foster_load, 300, 0, 600))
  expect_equal(monotony_strain(x),
               monotony_strain(x, window = 7, same_day_load = "include"))
})

# 4. Identity exclude(t) = include(t - 1) --------------------------------------

long_load <- c(300, 0, 450, 500, 0, 0, 620, 410, 380, 0, 700, 250, 0, 0,
               520, 480, 300, 0, 650, 440, 0, 390, 0, 0, 800, 270, 330, 0)

test_that("rolling_load(): exclude(t) equals include(t - 1)", {
  x <- daily(long_load)
  n <- length(long_load)
  for (k in c(1, 3, 7, 28)) {
    inc <- rolling_load(x, window = k, same_day_load = "include")
    exc <- rolling_load(x, window = k, same_day_load = "exclude")
    expect_equal(exc$rolling_sum[-1], inc$rolling_sum[-n], label = k)
    expect_equal(exc$rolling_mean[-1], inc$rolling_mean[-n], label = k)
    expect_true(is.na(exc$rolling_sum[1]))
  }
})

test_that("monotony_strain(): exclude(t) equals include(t - 1)", {
  x <- daily(long_load)
  n <- length(long_load)
  cols <- c("window_load", "mean_load", "sd_load", "monotony", "strain")
  for (k in c(2, 7, 14)) {
    inc <- monotony_strain(x, window = k, same_day_load = "include")
    exc <- monotony_strain(x, window = k, same_day_load = "exclude")
    for (col in cols) {
      expect_equal(exc[[col]][-1], inc[[col]][-n], label = paste(col, k))
    }
  }
})

# 5. Missing days (D-016) -------------------------------------------------------

test_that("a missing day makes every rolling window containing it NA", {
  load <- c(1, 2, 3, 4, NA, 6, 7, 8, 9, 10)
  x <- daily(load)

  inc <- rolling_load(x, window = 3, same_day_load = "include")
  # Windows ending on days 5, 6, 7 contain day 5.
  expect_equal(inc$rolling_sum, c(NA, NA, 6, 9, NA, NA, NA, 21, 24, 27))

  exc <- rolling_load(x, window = 3, same_day_load = "exclude")
  # Windows ending the day before days 6, 7, 8 contain day 5.
  expect_equal(exc$rolling_sum, c(NA, NA, NA, 6, 9, NA, NA, NA, 21, 24))
  expect_equal(exc$rolling_mean, exc$rolling_sum / 3)
})

test_that("a missing day makes every monotony window containing it NA", {
  load <- c(1, 2, 3, 4, NA, 6, 8, 8, 9, 10)
  out <- monotony_strain(daily(load), window = 3)
  cols <- c("window_load", "mean_load", "sd_load", "monotony", "strain")
  for (col in cols) {
    expect_true(all(is.na(out[[col]][c(1, 2, 5, 6, 7)])), label = col)
    expect_false(any(is.na(out[[col]][c(3, 4, 8, 9, 10)])), label = col)
  }
  # Day 8: loads 6, 8, 8.
  expect_equal(out$window_load[8], 22)
  expect_equal(out$mean_load[8], 22 / 3)
  expect_equal(out$sd_load[8], sd(c(6, 8, 8)))
})

test_that("days filled as missing by as_daily_load() give NA windows", {
  x <- suppressMessages(as_daily_load(
    data.frame(date = as.Date("2026-01-01") + c(0:2, 4:6), load = 1:6),
    date = "date", load = "load", gaps = "missing"
  ))
  out <- rolling_load(x, window = 2)
  expect_equal(out$rolling_sum, c(NA, 3, 5, NA, NA, 9, 11))
})

# 6. Equal loads: SD 0 (D-022) --------------------------------------------------

test_that("seven equal loads give sd 0 and NA monotony and strain", {
  out <- monotony_strain(daily(rep(400, 7)))
  expect_equal(out$window_load[7], 2800)
  expect_equal(out$mean_load[7], 400)
  expect_equal(out$sd_load[7], 0)
  expect_true(is.na(out$monotony[7]))
  expect_true(is.na(out$strain[7]))
})

test_that("seven rest days give sd 0 and NA monotony and strain", {
  out <- monotony_strain(daily(rep(0, 7)))
  expect_equal(out$window_load[7], 0)
  expect_equal(out$mean_load[7], 0)
  expect_equal(out$sd_load[7], 0)
  expect_true(is.na(out$monotony[7]))
  expect_true(is.na(out$strain[7]))
})

test_that("rest days count as load 0 in monotony", {
  out <- monotony_strain(daily(c(500, 0, 500, 0)), window = 4)
  expect_equal(out$mean_load[4], 250)
  expect_equal(out$sd_load[4], sd(c(500, 0, 500, 0)))
  expect_equal(out$monotony[4], 250 / sd(c(500, 0, 500, 0)))
  expect_equal(out$strain[4], 1000 * 250 / sd(c(500, 0, 500, 0)))
})

# 7. Several athletes -----------------------------------------------------------

test_that("windows never cross athletes and rows keep the input order", {
  a <- c(100, 200, 300, 400, 500, 600, 700, 800)
  b <- c(50, 0, 70, 0, 90)
  both <- as_daily_load(
    data.frame(id = c(rep("A", 8), rep("B", 5)),
               date = as.Date("2026-01-01") + c(0:7, 3:7),
               load = c(a, b)),
    date = "date", load = "load", athlete = "id"
  )
  alone_a <- daily(a, start = "2026-01-01", athlete = "A")
  alone_b <- daily(b, start = "2026-01-04", athlete = "B")

  for (timing in c("include", "exclude")) {
    out <- rolling_load(both, window = 3, same_day_load = timing)
    expect_identical(out$athlete, both$athlete)
    expect_identical(out$date, both$date)
    expect_equal(out$rolling_sum,
                 c(rolling_load(alone_a, 3, timing)$rolling_sum,
                   rolling_load(alone_b, 3, timing)$rolling_sum))

    out <- monotony_strain(both, window = 3, same_day_load = timing)
    expect_identical(out$athlete, both$athlete)
    expect_identical(out$date, both$date)
    expect_equal(out$monotony,
                 c(monotony_strain(alone_a, 3, timing)$monotony,
                   monotony_strain(alone_b, 3, timing)$monotony))
    expect_equal(out$strain,
                 c(monotony_strain(alone_a, 3, timing)$strain,
                   monotony_strain(alone_b, 3, timing)$strain))
  }
  # Athlete B's first window is complete only on its own third day.
  out <- rolling_load(both, window = 3)
  expect_equal(out$rolling_sum[9:13], c(NA, NA, 120, 70, 160))
})

# 8. Window argument ------------------------------------------------------------

test_that("a window longer than the series gives NA everywhere", {
  x <- daily(1:5)
  for (timing in c("include", "exclude")) {
    out <- rolling_load(x, window = 6, same_day_load = timing)
    expect_true(all(is.na(out$rolling_sum)))
    expect_true(all(is.na(out$rolling_mean)))
    out <- monotony_strain(x, window = 6, same_day_load = timing)
    expect_true(all(is.na(out$monotony)))
    expect_true(all(is.na(out$sd_load)))
  }
  # "exclude" needs window + 1 days.
  out <- rolling_load(x, window = 5, same_day_load = "exclude")
  expect_true(all(is.na(out$rolling_sum)))
})

test_that("invalid window values are errors", {
  x <- daily(1:10)
  bad <- list(0, -1, 2.5, NA, NA_real_, Inf, "7", c(3, 4), numeric(0), TRUE)
  for (w in bad) {
    expect_error(rolling_load(x, window = w), "window", label = deparse(w))
    expect_error(monotony_strain(x, window = w), "window", label = deparse(w))
  }
})

test_that("window = 1 is valid for rolling_load() and an error for monotony", {
  x <- daily(1:5)
  expect_equal(rolling_load(x, window = 1)$rolling_sum, as.numeric(1:5))
  expect_error(monotony_strain(x, window = 1), "window")
})

test_that("invalid same_day_load values are errors", {
  x <- daily(1:10)
  for (s in list("both", NA, c("include", "exclude", "x"), 1)) {
    expect_error(rolling_load(x, same_day_load = s), "same_day_load")
    expect_error(monotony_strain(x, same_day_load = s), "same_day_load")
  }
})

# 9. Output shape (A-011) ------------------------------------------------------

test_that("rolling_load() returns a plain data frame of fixed shape", {
  x <- daily(c(1, 0, 3, NA, 5, 6))
  out <- rolling_load(x, window = 2, same_day_load = "exclude")

  expect_identical(class(out), "data.frame")
  expect_identical(names(out),
                   c("athlete", "date", "load", "rolling_sum", "rolling_mean"))
  expect_identical(nrow(out), nrow(x))
  expect_identical(out$athlete, x$athlete)
  expect_identical(out$date, x$date)
  expect_identical(out$load, x$load)
  expect_type(out$athlete, "character")
  expect_s3_class(out$date, "Date")
  expect_type(out$load, "double")
  expect_type(out$rolling_sum, "double")
  expect_type(out$rolling_mean, "double")
  expect_identical(rownames(out), as.character(seq_len(nrow(x))))
  expect_equal(attr(out, "window"), 2)
  expect_identical(attr(out, "same_day_load"), "exclude")
})

test_that("monotony_strain() returns a plain data frame of fixed shape", {
  x <- daily(c(foster_load, NA, 300))
  out <- monotony_strain(x, window = 3, same_day_load = "include")

  expect_identical(class(out), "data.frame")
  expect_identical(names(out),
                   c("athlete", "date", "load", "window_load", "mean_load",
                     "sd_load", "monotony", "strain"))
  expect_identical(nrow(out), nrow(x))
  expect_identical(out$athlete, x$athlete)
  expect_identical(out$date, x$date)
  expect_identical(out$load, x$load)
  for (col in c("load", "window_load", "mean_load", "sd_load", "monotony",
                "strain")) {
    expect_type(out[[col]], "double")
  }
  expect_identical(rownames(out), as.character(seq_len(nrow(x))))
  expect_equal(attr(out, "window"), 3)
  expect_identical(attr(out, "same_day_load"), "include")
})

test_that("the performance column is not carried into the output", {
  x <- as_daily_load(
    data.frame(date = as.Date("2026-01-01") + 0:3, load = 1:4,
               jump = c(40, NA, 41, NA)),
    date = "date", load = "load", performance = "jump"
  )
  expect_identical(names(rolling_load(x, 2))[1:3],
                   c("athlete", "date", "load"))
  expect_false("performance" %in% names(rolling_load(x, 2)))
  expect_false("performance" %in% names(monotony_strain(x, 2)))
})
