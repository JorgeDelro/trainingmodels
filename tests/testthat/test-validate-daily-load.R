# Tests for the internal validator of daily_load objects (issue #4;
# DECISIONS.md, A-011). Each test breaks one invariant of as_daily_load() and
# checks that every function taking a daily_load refuses the object.

valid_daily <- function() {
  as_daily_load(
    data.frame(id = c(rep("A", 5), rep("B", 4)),
               date = as.Date("2026-01-01") + c(0:4, 0:3),
               load = c(100, 0, 300, 400, 500, 60, 70, 0, 90)),
    date = "date", load = "load", athlete = "id"
  )
}

# Functions that take a daily_load, called with arguments valid for `x`.
consumers <- list(
  rolling_load = function(x) rolling_load(x, window = 2),
  monotony_strain = function(x) monotony_strain(x, window = 2)
)

expect_invalid <- function(x, pattern = "no longer a valid daily_load") {
  for (name in names(consumers)) {
    expect_error(consumers[[name]](x), pattern, label = name)
    expect_error(consumers[[name]](x), "as_daily_load\\(\\)", label = name)
  }
}

test_that("a valid daily_load is accepted", {
  x <- valid_daily()
  for (f in consumers) expect_no_error(f(x))
  expect_no_error(validate_daily_load(x))
})

test_that("a plain data frame is refused", {
  x <- valid_daily()
  expect_invalid(as.data.frame(x), "daily_load")
  expect_invalid(data.frame(date = as.Date("2026-01-01") + 0:2,
                            load = c(1, 2, 3)), "daily_load")
})

test_that("a daily_load with a middle row removed is refused", {
  expect_invalid(valid_daily()[-3, ])
})

test_that("a daily_load with rows reordered is refused", {
  x <- valid_daily()
  expect_invalid(x[order(x$load), ])
  expect_invalid(x[c(2, 1, 3:9), ])
})

test_that("a status that contradicts the load is refused", {
  x <- valid_daily()
  x$load[3] <- 0
  expect_invalid(x)

  x <- valid_daily()
  x$load[2] <- NA
  expect_invalid(x)
})

test_that("a daily_load with a missing attribute is refused", {
  x <- valid_daily()
  attr(x, "load_name") <- NULL
  expect_invalid(x)

  x <- valid_daily()
  attr(x, "gaps") <- NULL
  expect_invalid(x)
})

test_that("a daily_load with a missing or retyped column is refused", {
  x <- valid_daily()
  x$status <- NULL
  expect_invalid(x)

  x <- valid_daily()
  x$date <- as.character(x$date)
  expect_invalid(x)
})
