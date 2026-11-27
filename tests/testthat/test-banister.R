# Tests for simulate_banister(), session_response(), constant_training(),
# half_life() and time_constant() (MODELS.md, M-01 to M-05; DECISIONS.md,
# D-011, D-012, D-016, D-023 to D-026, A-011, A-012). Expected values are
# literals that can be checked by hand, or reference values recorded in
# MODELS.md (Morton et al. 1990; Clarke & Skiba 2013; Ceddia et al. 2025).

# A daily_load with one row per day from `start`, one athlete unless
# `athlete` is given. Every day has a row, so no day is filled.
daily <- function(load, start = "2026-01-01", athlete = NULL,
                  performance = NULL) {
  dates <- as.Date(start) + seq_along(load) - 1L
  data <- data.frame(date = dates, load = load)
  if (!is.null(athlete)) data$id <- athlete
  if (!is.null(performance)) data$perf <- performance
  as_daily_load(data, date = "date", load = "load",
                athlete = if (is.null(athlete)) NULL else "id",
                performance = if (is.null(performance)) NULL else "perf")
}

# Absolute tolerance, as stated for the reference values.
expect_near <- function(object, expected, tol = 1e-4) {
  expect_identical(length(object), length(expected))
  expect_false(anyNA(object))
  expect_lte(max(abs(object - expected)), tol)
}

# Morton et al. 1990 example (MODELS.md, M-02 and M-04): load 100 on days
# 1-60, then 0 to day 120.
morton <- daily(c(rep(100, 60), rep(0, 60)))
morton_sim <- function(same_day_load, ...) {
  simulate_banister(morton, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15, p0 = 0,
                    same_day_load = same_day_load, ...)
}

# A 60-day irregular series with rest days.
irregular <- (1:60 * 37) %% 11 * 50

# 1. Hand example: daily decay 0.5 (M-01) ------------------------------------

test_that("fitness and fatigue follow M-01 with daily decay 0.5", {
  x <- daily(c(100, 0, 50))
  tau <- 1 / log(2)
  inc <- simulate_banister(x, k1 = 1, tau1 = tau, k2 = 1, tau2 = tau,
                           same_day_load = "include")
  exc <- simulate_banister(x, k1 = 1, tau1 = tau, k2 = 1, tau2 = tau,
                           same_day_load = "exclude")
  expect_equal(inc$fitness, c(100, 50, 75))
  expect_equal(inc$fatigue, c(100, 50, 75))
  expect_equal(exc$fitness, c(0, 50, 25))
  expect_equal(exc$fatigue, c(0, 50, 25))
})

test_that("an initial state adds g0 * exp(-t / tau) under both conventions", {
  x <- daily(c(100, 0, 50))
  tau <- 1 / log(2)
  inc <- simulate_banister(x, k1 = 1, tau1 = tau, k2 = 1, tau2 = tau,
                           same_day_load = "include",
                           initial_fitness = 40, initial_fatigue = 40)
  exc <- simulate_banister(x, k1 = 1, tau1 = tau, k2 = 1, tau2 = tau,
                           same_day_load = "exclude",
                           initial_fitness = 40, initial_fatigue = 40)
  expect_equal(inc$fitness, c(120, 60, 80))
  expect_equal(inc$fatigue, c(120, 60, 80))
  expect_equal(exc$fitness, c(20, 60, 30))
  expect_equal(exc$fatigue, c(20, 60, 30))
})

test_that("the default convention is 'exclude' (D-012)", {
  x <- daily(c(100, 0, 50))
  expect_equal(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                 same_day_load = "exclude"))
  expect_identical(
    attr(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
         "same_day_load"),
    "exclude"
  )
})

# 2. Morton et al. 1990 (M-02, M-04) ----------------------------------------

test_that("simulate_banister() reproduces Morton et al. 1990, 'include'", {
  out <- morton_sim("include")
  p <- out$predicted
  expect_near(out$fitness[60], 3350.7694)
  expect_near(out$fatigue[60], 1522.1561)
  expect_near(p[60], 306.4572)
  expect_identical(which.min(p), 16L)
  expect_near(min(p), -672.3638)
  expect_near(p[47], -16.9554)
  expect_near(p[48], 9.5188)
  expect_identical(60L + which.max(p[61:120]), 83L)
  expect_near(max(p[61:120]), 1352.8793)
})

test_that("simulate_banister() reproduces Morton's example, 'exclude'", {
  out <- morton_sim("exclude")
  p <- out$predicted
  expect_near(out$fitness[60], 3250.7694)
  expect_near(out$fatigue[60], 1422.1561)
  expect_near(p[60], 406.4572)
  expect_identical(which.min(p), 16L)
  expect_near(min(p), -572.3638)
  expect_identical(60L + which.max(p[61:120]), 83L)
  expect_near(max(p[61:120]), 1352.8793)
})

test_that("fitness on day 61 is the same under both conventions", {
  expect_near(morton_sim("include")$fitness[61], 3277.1291)
  expect_near(morton_sim("exclude")$fitness[61], 3277.1291)
})

test_that("stopping from steady state peaks on day 16 at 2121.4379", {
  x <- daily(rep(0, 40))
  for (convention in c("include", "exclude")) {
    out <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             same_day_load = convention,
                             initial_fitness = 4550.1852,
                             initial_fatigue = 1550.5555)
    expect_identical(which.max(out$predicted), 16L)
    expect_near(max(out$predicted), 2121.4379)
  }
})

# 3. Identities between the conventions (M-01) -------------------------------

test_that("g_inc(t) = g_exc(t) + w(t) and g_exc(t+1) = exp(-1/tau) g_inc(t)", {
  x <- daily(irregular)
  w <- irregular
  for (init in list(c(0, 0), c(300, 120))) {
    inc <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             same_day_load = "include",
                             initial_fitness = init[1],
                             initial_fatigue = init[2])
    exc <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             same_day_load = "exclude",
                             initial_fitness = init[1],
                             initial_fatigue = init[2])
    expect_equal(inc$fitness, exc$fitness + w)
    expect_equal(inc$fatigue, exc$fatigue + w)
    expect_equal(exc$fitness[-1], exp(-1 / 45) * inc$fitness[-60])
    expect_equal(exc$fatigue[-1], exp(-1 / 15) * inc$fatigue[-60])
  }
})

test_that("predicted is p0 + k1 * fitness - k2 * fatigue", {
  out <- simulate_banister(daily(irregular), k1 = 0.8, tau1 = 40, k2 = 1.7,
                           tau2 = 12, p0 = 250)
  expect_equal(out$predicted, 250 + 0.8 * out$fitness - 1.7 * out$fatigue)
})

# 4. constant_training() (M-04) ---------------------------------------------

test_that("constant_training() gives Morton's asymptote and minimum", {
  # The asymptote depends on the convention: p_exc = p_inc - (k1 - k2) * T.
  asymptote <- c(include = 1449.0742, exclude = 1549.0742)
  for (convention in c("include", "exclude")) {
    out <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             same_day_load = convention)
    expect_near(out$asymptote, asymptote[[convention]])
    expect_near(out$time_of_minimum, 16.0921)
  }
})

test_that("the last value of a long curve equals the asymptote", {
  for (convention in c("include", "exclude")) {
    out <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             days = 3000, same_day_load = convention)
    expect_near(out$curve$predicted[3000], out$asymptote, tol = 1e-6)
  }
})

test_that("constant_training() curve equals simulate_banister()", {
  x <- daily(rep(100, 100))
  for (convention in c("include", "exclude")) {
    closed <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                p0 = 500, same_day_load = convention)
    sim <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             p0 = 500, same_day_load = convention)
    expect_identical(closed$curve$day, 1:100)
    expect_equal(closed$curve$fitness, sim$fitness)
    expect_equal(closed$curve$fatigue, sim$fatigue)
    expect_equal(closed$curve$predicted, sim$predicted)
  }
})

test_that("constant_training() asymptote includes p0", {
  # Default convention "exclude".
  out <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                           p0 = 500)
  expect_near(out$asymptote, 2049.0742)
})

test_that("time_of_minimum is NA when there is no minimum (D-026)", {
  # Argument of the logarithm < 1: no minimum.
  expect_true(is.na(constant_training(100, k1 = 1, tau1 = 45, k2 = 0.5,
                                      tau2 = 15)$time_of_minimum))
  # tau1 <= tau2.
  expect_true(is.na(constant_training(100, k1 = 1, tau1 = 15, k2 = 2,
                                      tau2 = 45)$time_of_minimum))
  expect_true(is.na(constant_training(100, k1 = 1, tau1 = 20, k2 = 2,
                                      tau2 = 20)$time_of_minimum))
  # k1 = 0: performance only falls.
  expect_true(is.na(constant_training(100, k1 = 0, tau1 = 45, k2 = 2,
                                      tau2 = 15)$time_of_minimum))
  # Fitness-only model.
  expect_true(is.na(constant_training(100, k1 = 1, tau1 = 45,
                                      model = "fitness_only")$time_of_minimum))
})

test_that("constant_training() returns its documented structure", {
  out <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                           days = 30)
  expect_s3_class(out, "constant_training")
  expect_true(all(c("curve", "asymptote", "time_of_minimum") %in%
                    names(out)))
  expect_identical(names(out$curve),
                   c("day", "fitness", "fatigue", "predicted"))
  expect_identical(out$curve$day, 1:30)
  expect_identical(out$same_day_load, "exclude")
  expect_identical(out$model, "two_component")

  fo <- constant_training(100, k1 = 1, tau1 = 45, model = "fitness_only")
  expect_true(all(is.na(fo$curve$fatigue)))
  expect_equal(fo$curve$predicted, fo$curve$fitness)
  expect_near(fo$asymptote, 4450.1852)
  fo_inc <- constant_training(100, k1 = 1, tau1 = 45, model = "fitness_only",
                              same_day_load = "include")
  expect_near(fo_inc$asymptote, 4550.1852)
})

# 5. session_response() (M-05) ----------------------------------------------

test_that("session_response() gives Morton's times and peak effect", {
  out <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
  expect_near(out$time_to_recover, 15.5958)
  expect_near(out$time_to_peak, 40.3146)
  expect_near(out$peak_effect, 0.272166)
})

test_that("session_response() reproduces Clarke & Skiba and Ceddia", {
  cs <- session_response(k1 = 0.18258, tau1 = 35.821, k2 = 0.23016,
                         tau2 = 21.340)
  expect_near(cs$time_to_recover, 12.2249)
  expect_near(cs$time_to_peak, 39.5664)
  ce <- session_response(k1 = 0.048, tau1 = 38, k2 = 0.117, tau2 = 1.9)
  expect_near(ce$time_to_recover, 1.7819, tol = 1e-3)
  expect_near(ce$time_to_peak, 7.7734, tol = 1e-3)
})

test_that("the times do not depend on the convention", {
  inc <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                          same_day_load = "include")
  exc <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                          same_day_load = "exclude")
  expect_identical(inc$time_to_recover, exc$time_to_recover)
  expect_identical(inc$time_to_peak, exc$time_to_peak)
  expect_identical(inc$peak_effect, exc$peak_effect)
})

test_that("the curve follows the convention on day 0 only", {
  u <- 1:60
  expected <- 1 * exp(-u / 45) - 2 * exp(-u / 15)
  inc <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                          same_day_load = "include")
  exc <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                          same_day_load = "exclude")
  expect_identical(names(inc$curve), c("day", "effect"))
  expect_identical(inc$curve$day, 0:60)
  expect_equal(inc$curve$effect[1], 1 - 2)
  expect_equal(exc$curve$effect[1], 0)
  expect_equal(inc$curve$effect[-1], expected)
  expect_equal(exc$curve$effect[-1], expected)
  expect_identical(session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                    days = 10)$curve$day, 0:10)
})

test_that("the curve equals a simulation of one unit of load", {
  x <- daily(c(1, rep(0, 60)))
  for (convention in c("include", "exclude")) {
    sim <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             same_day_load = convention)
    curve <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                              same_day_load = convention)$curve
    expect_equal(sim$predicted, curve$effect)
  }
})

test_that("time_to_recover and time_to_peak are NA when they do not exist", {
  # k2 <= k1: never negative, so no recovery time; the peak still exists.
  out <- session_response(k1 = 1, tau1 = 45, k2 = 1, tau2 = 15)
  expect_true(is.na(out$time_to_recover))
  expect_false(is.na(out$time_to_peak))
  out <- session_response(k1 = 1, tau1 = 45, k2 = 0.5, tau2 = 15)
  expect_true(is.na(out$time_to_recover))
  # k2 * tau1 <= k1 * tau2: no peak after day 0.
  out <- session_response(k1 = 1, tau1 = 45, k2 = 0.3, tau2 = 15)
  expect_true(is.na(out$time_to_recover))
  expect_true(is.na(out$time_to_peak))
  expect_true(is.na(out$peak_effect))
  # tau1 <= tau2.
  for (taus in list(c(15, 45), c(20, 20))) {
    out <- session_response(k1 = 1, tau1 = taus[1], k2 = 2, tau2 = taus[2])
    expect_true(is.na(out$time_to_recover))
    expect_true(is.na(out$time_to_peak))
    expect_true(is.na(out$peak_effect))
  }
  # k1 = 0: the effect is never positive.
  out <- session_response(k1 = 0, tau1 = 45, k2 = 2, tau2 = 15)
  expect_true(is.na(out$time_to_recover))
  expect_true(is.na(out$time_to_peak))
  # Fitness-only model.
  out <- session_response(k1 = 1, tau1 = 45, model = "fitness_only")
  expect_true(is.na(out$time_to_recover))
  expect_true(is.na(out$time_to_peak))
  expect_true(is.na(out$peak_effect))
  expect_equal(out$curve$effect[-1], exp(-(1:60) / 45))
})

test_that("session_response() returns its documented structure", {
  out <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
  expect_s3_class(out, "session_response")
  expect_true(all(c("curve", "time_to_recover", "time_to_peak",
                    "peak_effect", "model", "same_day_load", "days") %in%
                    names(out)))
  expect_identical(out$same_day_load, "exclude")
  expect_identical(out$model, "two_component")
  expect_identical(out$days, 60)
})

# 6. Fitness-only model (M-03, D-023) ----------------------------------------

test_that("fitness_only predicts p0 + k1 * fitness with NA fatigue", {
  out <- simulate_banister(daily(irregular), k1 = 0.5, tau1 = 45, p0 = 100,
                           model = "fitness_only")
  expect_true(all(is.na(out$fatigue)))
  expect_type(out$fatigue, "double")
  expect_equal(out$predicted, 100 + 0.5 * out$fitness)
})

test_that("fitness_only equals two_component with k2 = 0", {
  x <- daily(irregular)
  for (convention in c("include", "exclude")) {
    fo <- simulate_banister(x, k1 = 0.5, tau1 = 45, p0 = 100,
                            model = "fitness_only",
                            same_day_load = convention,
                            initial_fitness = 200)
    tc <- simulate_banister(x, k1 = 0.5, tau1 = 45, k2 = 0, tau2 = 15,
                            p0 = 100, same_day_load = convention,
                            initial_fitness = 200)
    expect_equal(fo$fitness, tc$fitness)
    expect_equal(fo$predicted, tc$predicted)
  }
})

test_that("fitness_only refuses k2, tau2 and a non-zero initial fatigue", {
  x <- daily(irregular)
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2,
                                 model = "fitness_only"), "k2")
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, tau2 = 15,
                                 model = "fitness_only"), "tau2")
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45,
                                 model = "fitness_only",
                                 initial_fatigue = 10), "initial_fatigue")
  expect_no_error(simulate_banister(x, k1 = 1, tau1 = 45,
                                    model = "fitness_only",
                                    initial_fatigue = 0))
  expect_error(session_response(k1 = 1, tau1 = 45, k2 = 2,
                                model = "fitness_only"), "k2")
  expect_error(constant_training(100, k1 = 1, tau1 = 45, tau2 = 15,
                                 model = "fitness_only"), "tau2")
})

test_that("two_component needs k2 and tau2", {
  x <- daily(irregular)
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, tau2 = 15), "k2")
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2), "tau2")
  expect_error(session_response(k1 = 1, tau1 = 45), "k2")
  expect_error(constant_training(100, k1 = 1, tau1 = 45, k2 = 2), "tau2")
})

# 7. half_life() and time_constant() (D-024) ---------------------------------

test_that("half_life() is tau * log(2) and time_constant() inverts it", {
  expect_near(half_life(45), 31.1916)
  expect_near(half_life(15), 10.3972)
  expect_equal(half_life(c(45, 15)), c(45, 15) * log(2))
  expect_equal(time_constant(half_life(c(45, 15, 1.9))), c(45, 15, 1.9))
  expect_equal(time_constant(7), 7 / log(2))
})

test_that("half_life() and time_constant() accept positive finite numbers only", {
  for (f in list(half_life, time_constant)) {
    expect_error(f(0))
    expect_error(f(-1))
    expect_error(f(Inf))
    expect_error(f(NA))
    expect_error(f(c(10, NA)))
    expect_error(f("45"))
    expect_error(f(numeric(0)))
  }
})

# 8. Missing loads (D-016) ----------------------------------------------------

test_that("missing loads are an error naming the first missing day", {
  x <- daily(c(100, 50, NA, 80, NA))
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "2026-01-03")
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "missing_load = \"zero\"", fixed = TRUE)
})

test_that("missing_load = 'zero' counts missing loads as 0, with a message", {
  x <- daily(c(100, 50, NA, 80, NA))
  expect_message(
    out <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                             missing_load = "zero"),
    "2 days"
  )
  ref <- simulate_banister(daily(c(100, 50, 0, 80, 0)), k1 = 1, tau1 = 45,
                           k2 = 2, tau2 = 15)
  expect_equal(out$fitness, ref$fitness)
  expect_equal(out$fatigue, ref$fatigue)
  expect_equal(out$predicted, ref$predicted)
  # The load column shows the input as it was: missing days stay NA.
  expect_identical(out$load, x$load)
})

test_that("missing_load = 'zero' gives no message without missing loads", {
  expect_no_message(simulate_banister(daily(irregular), k1 = 1, tau1 = 45,
                                      k2 = 2, tau2 = 15,
                                      missing_load = "zero"))
})

# 9. Several athletes, observed performance ---------------------------------

test_that("two athletes give the same results as each processed alone", {
  load_a <- irregular[1:40]
  load_b <- rev(irregular)
  both <- as_daily_load(
    data.frame(id = c(rep("A", 40), rep("B", 60)),
               date = c(as.Date("2026-01-01") + 0:39,
                        as.Date("2026-02-10") + 0:59),
               load = c(load_a, load_b)),
    date = "date", load = "load", athlete = "id"
  )
  args <- list(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15, p0 = 10,
               initial_fitness = 50, initial_fatigue = 20)
  out <- do.call(simulate_banister, c(list(both), args))
  a <- do.call(simulate_banister, c(list(daily(load_a)), args))
  b <- do.call(simulate_banister,
               c(list(daily(load_b, start = "2026-02-10")), args))
  expect_identical(out$athlete, both$athlete)
  expect_identical(out$date, both$date)
  for (col in c("fitness", "fatigue", "predicted")) {
    expect_equal(out[[col]], c(a[[col]], b[[col]]))
  }
})

test_that("the observed column is carried when x has performance", {
  perf <- c(NA, 40.1, NA, NA, 41.0, NA)
  out <- simulate_banister(daily(c(100, 0, 50, 80, 0, 60), performance = perf),
                           k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
  expect_identical(names(out), c("athlete", "date", "load", "fitness",
                                 "fatigue", "predicted", "observed"))
  expect_identical(out$observed, perf)
  expect_false("observed" %in% names(simulate_banister(
    daily(c(100, 0, 50)), k1 = 1, tau1 = 45, k2 = 2, tau2 = 15
  )))
})

# 10. Argument checks ----------------------------------------------------------

test_that("invalid parameters are errors naming the argument", {
  x <- daily(irregular)
  good <- list(x = x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15, p0 = 0,
               initial_fitness = 0, initial_fatigue = 0)
  bad_values <- list(
    k1 = list(-1, NA, Inf, c(1, 2), "1", NULL),
    k2 = list(-1, NA, Inf, c(1, 2), "1"),
    tau1 = list(0, -45, Inf, NA, c(45, 40), "45", NULL),
    tau2 = list(0, -15, Inf, NA, c(15, 10), "15"),
    p0 = list(NA, Inf, c(0, 1), "0"),
    initial_fitness = list(-1, NA, Inf, c(0, 1), "0"),
    initial_fatigue = list(-1, NA, Inf, c(0, 1), "0")
  )
  for (arg in names(bad_values)) {
    for (value in bad_values[[arg]]) {
      args <- good
      args[arg] <- list(value)
      expect_error(do.call(simulate_banister, args), arg,
                   info = paste(arg, format(value)))
    }
  }
  expect_no_error(simulate_banister(x, k1 = 0, tau1 = 45, k2 = 0, tau2 = 15,
                                    p0 = -20))
})

test_that("invalid option values are errors", {
  x <- daily(irregular)
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                 same_day_load = "both"), "same_day_load")
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                 model = "three"))
  expect_error(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                 missing_load = "mean"))
})

test_that("session_response() and constant_training() check their arguments", {
  expect_error(session_response(k1 = 1, tau1 = 0, k2 = 2, tau2 = 15), "tau1")
  expect_error(session_response(k1 = -1, tau1 = 45, k2 = 2, tau2 = 15), "k1")
  expect_error(session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                days = 0), "days")
  expect_error(session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                days = 2.5), "days")
  expect_error(constant_training(0, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "load")
  expect_error(constant_training(-100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "load")
  expect_error(constant_training(c(100, 50), k1 = 1, tau1 = 45, k2 = 2,
                                 tau2 = 15), "load")
  expect_error(constant_training(NA, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "load")
  expect_error(constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = Inf),
               "tau2")
  expect_error(constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                                 days = -1), "days")
})

test_that("an invalid daily_load is refused by the validator", {
  expect_error(simulate_banister(data.frame(date = Sys.Date(), load = 1),
                                 k1 = 1, tau1 = 45, k2 = 2, tau2 = 15),
               "daily_load")
  x <- daily(c(100, 0, 50, 80))
  expect_error(simulate_banister(x[-2, ], k1 = 1, tau1 = 45, k2 = 2,
                                 tau2 = 15),
               "no longer a valid daily_load")
})

# 11. Output shape and attributes (A-011, A-012) ----------------------------

test_that("simulate_banister() returns one row per row of x, with attributes", {
  x <- daily(irregular)
  out <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15, p0 = 5,
                           initial_fitness = 40, initial_fatigue = 10)
  expect_s3_class(out, c("banister_sim", "data.frame"), exact = TRUE)
  expect_identical(names(out), c("athlete", "date", "load", "fitness",
                                 "fatigue", "predicted"))
  expect_identical(nrow(out), nrow(x))
  expect_identical(out$athlete, x$athlete)
  expect_identical(out$date, x$date)
  expect_identical(out$load, x$load)
  expect_identical(attr(out, "model"), "two_component")
  expect_identical(attr(out, "same_day_load"), "exclude")
  expect_equal(attr(out, "parameters"),
               c(p0 = 5, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15))
  expect_equal(attr(out, "initial_state"), c(fitness = 40, fatigue = 10))

  fo <- simulate_banister(x, k1 = 1, tau1 = 45, model = "fitness_only")
  expect_identical(attr(fo, "model"), "fitness_only")
  expect_equal(attr(fo, "parameters"), c(p0 = 0, k1 = 1, tau1 = 45))
})

# 12. Printed output (D-012, D-024, A-012) ----------------------------------

test_that("print() shows the model, convention, parameters and half-lives", {
  x <- daily(irregular)
  out <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
  text <- paste(capture.output(print(out)), collapse = "\n")
  expect_match(text, "exclude")
  expect_match(text, "two.component")
  expect_match(text, "tau1")
  expect_match(text, "45")
  expect_match(text, "half-life")
  expect_match(text, "31.19", fixed = TRUE)
  expect_match(text, "10.4", fixed = TRUE)
  expect_invisible(print(out))

  inc <- simulate_banister(x, k1 = 1, tau1 = 45, model = "fitness_only",
                           same_day_load = "include")
  text <- paste(capture.output(print(inc)), collapse = "\n")
  expect_match(text, "include")
  expect_match(text, "fitness.only")
})

test_that("print() of session_response and constant_training shows the times", {
  sr <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
  text <- paste(capture.output(print(sr)), collapse = "\n")
  expect_match(text, "15.6", fixed = TRUE)
  expect_match(text, "40.3", fixed = TRUE)
  expect_match(text, "31.19", fixed = TRUE)
  expect_match(text, "exclude")

  ct <- constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
                          same_day_load = "include")
  text <- paste(capture.output(print(ct)), collapse = "\n")
  expect_match(text, "16.09", fixed = TRUE)
  expect_match(text, "1449", fixed = TRUE)
  expect_match(text, "include")
})
