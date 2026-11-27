#' Simulate the Banister impulse-response model
#'
#' Computes fitness, fatigue and predicted performance for every day of a
#' daily training-load series, within each athlete, from parameters given by
#' the user (MODELS.md, M-01 to M-03). Nothing is fitted: this version only
#' simulates.
#'
#' @section Formula:
#' Fitness \eqn{g} and fatigue \eqn{h} are exponential filters of the daily
#' load \eqn{w} with time constants \eqn{\tau_1}{tau1} and \eqn{\tau_2}{tau2}
#' (MODELS.md, M-01). The two-component model (M-02) predicts
#' \deqn{p(t) = p_0 + k_1\,g(t) - k_2\,h(t),}{p(t) = p0 + k1 g(t) - k2 h(t),}
#' and the fitness-only model (M-03) predicts
#' \deqn{p(t) = p_0 + k_1\,g(t).}{p(t) = p0 + k1 g(t).}
#' The columns `fitness` and `fatigue` are \eqn{g} and \eqn{h} without their
#' gains. They are computed in recursive form.
#'
#' @section Timing convention and default:
#' * `same_day_load = "exclude"` (the default; Busso & Chalencon 2023): the
#'   load of day \eqn{t} affects performance from day \eqn{t + 1},
#'   \deqn{g(t) = [g(t-1) + w(t-1)]\,e^{-1/\tau}.}{g(t) = [g(t-1) + w(t-1)] exp(-1/tau).}
#'   This corresponds to a performance test done before that day's training.
#' * `same_day_load = "include"` (Morton et al. 1990, Eqs. 4-5): the load of
#'   day \eqn{t} counts on day \eqn{t} at full weight,
#'   \deqn{g(t) = g(t-1)\,e^{-1/\tau} + w(t).}{g(t) = g(t-1) exp(-1/tau) + w(t).}
#'
#' The two conventions give different numbers: gains obtained under one are
#' not comparable with the other. The default "exclude" (DECISIONS.md, D-012)
#' differs from the default of the load descriptors such as [rolling_load()],
#' which is "include" (D-021).
#'
#' @section Initial state:
#' Fitness and fatigue start from `initial_fitness` and `initial_fatigue`
#' on day 0, both 0 by default (D-025). An initial value \eqn{g_0} adds
#' \eqn{g_0\,e^{-t/\tau}}{g0 exp(-t/tau)} to day \eqn{t} under both
#' conventions (MODELS.md, M-01). Each athlete starts from the same initial
#' state on their first day.
#'
#' @section Missing loads:
#' Missing loads are never replaced silently (D-016). By default a series
#' with a missing load is an error that names the first missing day. With
#' `missing_load = "zero"` missing loads count as load 0 and a message says
#' how many; the `load` column of the result still shows them as `NA`.
#'
#' @param x A `daily_load` object, from [as_daily_load()]. It is checked
#'   first; an object changed after it was built (for example by subsetting)
#'   must be rebuilt with [as_daily_load()].
#' @param k1 Gain of fitness, a single finite number `>= 0`.
#' @param tau1 Time constant of fitness in days, a single finite number
#'   `> 0`. Arguments are time constants, never half-lives (D-024): see
#'   [time_constant()] to convert a half-life.
#' @param k2 Gain of fatigue, a single finite number `>= 0`. Required for the
#'   two-component model; must not be given for the fitness-only model.
#' @param tau2 Time constant of fatigue in days, a single finite number
#'   `> 0`. Required for the two-component model; must not be given for the
#'   fitness-only model.
#' @param p0 Baseline performance, a single finite number.
#' @param model `"two_component"` (the default; fitness and fatigue) or
#'   `"fitness_only"` (D-023).
#' @param same_day_load Timing convention: `"exclude"` (the default) or
#'   `"include"`. See the section on the timing convention.
#' @param initial_fitness,initial_fatigue Fitness and fatigue on day 0, single
#'   finite numbers `>= 0`. The fitness-only model has no fatigue, so
#'   `initial_fatigue` must be 0.
#' @param missing_load What to do with missing loads: `"error"` (the
#'   default) or `"zero"` to count them as load 0.
#'
#' @return An object of class `c("banister_sim", "data.frame")` with one row
#'   per row of `x`, in the same order, and the columns `athlete`, `date`,
#'   `load`, `fitness`, `fatigue` (`NA` for the fitness-only model),
#'   `predicted` and, if `x` has a performance column, `observed`. The
#'   attributes `model`, `same_day_load`, `parameters` (named numeric vector)
#'   and `initial_state` record the arguments used. Its print method shows
#'   them, with the half-life of each time constant.
#'
#' @references
#' Morton RH, Fitz-Clarke JR, Banister EW (1990). Modeling human performance
#' in running. *Journal of Applied Physiology*, 69(3), 1171-1177.
#'
#' Busso T, Chalencon S (2023). Validity and accuracy of impulse-response
#' models for modeling and predicting training effects on performance of
#' swimmers. *Medicine & Science in Sports & Exercise*, 55(7), 1274-1285.
#'
#' Marchal A, Benazieb O, Weldegebriel Y, Méline T, Imbach F (2025).
#' Statistical flaws of the fitness-fatigue sports performance prediction
#' model. *Scientific Reports*, 15, 3706.
#'
#' @seealso [session_response()] for the response to a single session,
#'   [constant_training()] for constant daily training, [half_life()],
#'   [as_daily_load()]. The article "The Banister model" on the package
#'   website discusses the limitations of the model.
#'
#' @examples
#' # Morton et al. (1990): load 100 on days 1-60, then 60 days of rest
#' x <- as_daily_load(
#'   data.frame(date = as.Date("2026-01-01") + 0:119,
#'              load = c(rep(100, 60), rep(0, 60))),
#'   date = "date", load = "load"
#' )
#' sim <- simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
#'                          same_day_load = "include")
#' sim
#' which.min(sim$predicted)
#'
#' # Fitness-only model, default convention "exclude"
#' simulate_banister(x, k1 = 1, tau1 = 45, model = "fitness_only")
#'
#' @export
simulate_banister <- function(x, k1, tau1, k2 = NULL, tau2 = NULL, p0 = 0,
                              model = c("two_component", "fitness_only"),
                              same_day_load = c("exclude", "include"),
                              initial_fitness = 0, initial_fatigue = 0,
                              missing_load = c("error", "zero")) {
  validate_daily_load(x)
  model <- check_choice(model, c("two_component", "fitness_only"), "model")
  same_day_load <- check_choice(same_day_load, c("exclude", "include"),
                                "same_day_load")
  missing_load <- check_choice(missing_load, c("error", "zero"),
                               "missing_load")
  parameters <- check_banister_parameters(model, k1, tau1, k2, tau2, p0)
  initial_fitness <- check_number(initial_fitness, "initial_fitness", min = 0)
  initial_fatigue <- check_number(initial_fatigue, "initial_fatigue", min = 0)
  two_component <- model == "two_component"
  if (!two_component && initial_fatigue != 0) {
    stop("`initial_fatigue` must be 0 for the fitness-only model, which has ",
         "no fatigue component.", call. = FALSE)
  }

  load <- x$load
  missing <- which(is.na(load))
  if (length(missing) > 0L) {
    if (missing_load == "error") {
      first <- missing[1L]
      stop(sprintf(
        "The load of athlete %s on %s is missing (%d %s with a missing load in total). Missing loads are not filled silently. To count them as load 0, use missing_load = \"zero\".",
        x$athlete[first], iso_date(x$date[first]), length(missing),
        if (length(missing) == 1L) "day" else "days"
      ), call. = FALSE)
    }
    message(sprintf("%d %s with a missing load counted as load 0.",
                    length(missing),
                    if (length(missing) == 1L) "day" else "days"))
    load[missing] <- 0
  }

  n <- nrow(x)
  fitness <- numeric(n)
  fatigue <- rep(NA_real_, n)
  # Rows of one athlete are contiguous and consecutive days
  # (validate_daily_load()).
  for (a in unique(x$athlete)) {
    rows <- which(x$athlete == a)
    fitness[rows] <- exp_filter(load[rows], parameters[["tau1"]],
                                same_day_load, initial_fitness)
    if (two_component) {
      fatigue[rows] <- exp_filter(load[rows], parameters[["tau2"]],
                                  same_day_load, initial_fatigue)
    }
  }
  predicted <- parameters[["p0"]] + parameters[["k1"]] * fitness
  if (two_component) predicted <- predicted - parameters[["k2"]] * fatigue

  out <- data.frame(athlete = x$athlete, date = x$date, load = x$load,
                    fitness = fitness, fatigue = fatigue,
                    predicted = predicted, stringsAsFactors = FALSE)
  if ("performance" %in% names(x)) out$observed <- x$performance
  initial_state <- if (two_component) {
    c(fitness = initial_fitness, fatigue = initial_fatigue)
  } else {
    c(fitness = initial_fitness)
  }
  structure(out, class = c("banister_sim", "data.frame"), model = model,
            same_day_load = same_day_load, parameters = parameters,
            initial_state = initial_state)
}

#' Print a Banister simulation
#'
#' Prints a header with the model, the timing convention, the parameters and
#' the half-life of each time constant (DECISIONS.md, A-012 and D-024),
#' followed by the first rows of the simulation.
#'
#' @param x A `banister_sim` object, from [simulate_banister()].
#' @param n Number of rows to print.
#' @param ... Passed to [print.data.frame()].
#'
#' @return `x`, invisibly.
#'
#' @examples
#' x <- as_daily_load(
#'   data.frame(date = as.Date("2026-01-01") + 0:9, load = rep(100, 10)),
#'   date = "date", load = "load"
#' )
#' print(simulate_banister(x, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15), n = 5)
#'
#' @export
print.banister_sim <- function(x, n = 10, ...) {
  rows <- x
  class(rows) <- "data.frame"
  attr(rows, "model") <- attr(rows, "same_day_load") <-
    attr(rows, "parameters") <- attr(rows, "initial_state") <- NULL
  model <- attr(x, "model")
  parameters <- attr(x, "parameters")
  # A subset made with `[` may have lost the attributes: print the rows only.
  if (!is.null(model) && !is.null(parameters)) {
    cat(sprintf("<banister_sim> Banister model simulation: %s\n",
                model_label(model)))
    cat(banister_header(parameters, attr(x, "same_day_load")), sep = "\n")
    initial <- attr(x, "initial_state")
    cat(sprintf("Initial state: %s\n", paste(
      names(initial), format_number(initial), sep = " ", collapse = ", "
    )))
    cat("Nothing is fitted: values are simulated from the parameters given.\n\n")
  }
  shown <- min(n, nrow(rows))
  print(rows[seq_len(shown), , drop = FALSE], ...)
  if (nrow(rows) > shown) {
    cat(sprintf("# ... %d more rows\n", nrow(rows) - shown))
  }
  invisible(x)
}

# Internal helpers --------------------------------------------------------------

# Exponential filter of M-01 in recursive form (A-004), starting from
# `initial` on day 0. Under "exclude" the load of day 0 is 0.
exp_filter <- function(load, tau, same_day_load, initial = 0) {
  decay <- exp(-1 / tau)
  out <- numeric(length(load))
  g <- initial
  previous_load <- 0
  for (t in seq_along(load)) {
    if (same_day_load == "include") {
      g <- g * decay + load[t]
    } else {
      g <- (g + previous_load) * decay
      previous_load <- load[t]
    }
    out[t] <- g
  }
  out
}

# Checks the parameters of either model and returns them as a named numeric
# vector: p0 (unless NULL), k1, tau1 and, for the two-component model, k2 and
# tau2.
check_banister_parameters <- function(model, k1, tau1, k2, tau2, p0 = NULL) {
  if (model == "fitness_only") {
    for (arg in c("k2", "tau2")) {
      if (!is.null(get(arg))) {
        stop(sprintf(
          "`%s` must not be given for the fitness-only model, which has no fatigue component.",
          arg
        ), call. = FALSE)
      }
    }
  } else {
    for (arg in c("k2", "tau2")) {
      if (is.null(get(arg))) {
        stop(sprintf(
          "`%s` is needed for the two-component model. For a model without fatigue, use model = \"fitness_only\".",
          arg
        ), call. = FALSE)
      }
    }
  }
  out <- c(k1 = check_number(k1, "k1", min = 0),
           tau1 = check_number(tau1, "tau1", min = 0, strict = TRUE))
  if (model == "two_component") {
    out <- c(out, k2 = check_number(k2, "k2", min = 0),
             tau2 = check_number(tau2, "tau2", min = 0, strict = TRUE))
  }
  if (!is.null(p0)) out <- c(p0 = check_number(p0, "p0"), out)
  out
}

# A single finite number, optionally >= min (or > min when strict).
check_number <- function(value, arg, min = -Inf, strict = FALSE) {
  ok <- is.numeric(value) && length(value) == 1L && is.finite(value) &&
    (if (strict) value > min else value >= min)
  if (!ok) {
    bound <- if (is.finite(min)) {
      sprintf(" %s %s", if (strict) ">" else ">=", format(min))
    } else {
      ""
    }
    stop(sprintf("`%s` must be a single finite number%s.", arg, bound),
         call. = FALSE)
  }
  as.double(value)
}

# A whole number of days >= 1.
check_days <- function(days) {
  if (!is.numeric(days) || length(days) != 1L || !is.finite(days) ||
      days != round(days) || days < 1) {
    stop("`days` must be a single whole number >= 1.", call. = FALSE)
  }
  days
}

# One of `choices`; the full default vector selects the first.
check_choice <- function(value, choices, arg) {
  if (identical(value, choices)) return(choices[1L])
  if (!is.character(value) || length(value) != 1L || is.na(value) ||
      !value %in% choices) {
    stop(sprintf("`%s` must be one of %s.", arg,
                 paste0("\"", choices, "\"", collapse = ", ")),
         call. = FALSE)
  }
  value
}

model_label <- function(model) {
  if (model == "two_component") "two-component model" else "fitness-only model"
}

# Each value to 4 significant digits, formatted on its own.
format_number <- function(x) {
  vapply(x, function(v) format(v, digits = 4), character(1))
}

# Header lines shared by the print methods: convention, gains and baseline,
# time constants with their half-lives.
banister_header <- function(parameters, same_day_load) {
  convention <- if (same_day_load == "exclude") {
    "\"exclude\" (a day's load affects performance from the next day)"
  } else {
    "\"include\" (a day's load counts on the same day)"
  }
  gains <- parameters[intersect(c("p0", "k1", "k2"), names(parameters))]
  taus <- parameters[intersect(c("tau1", "tau2"), names(parameters))]
  c(
    sprintf("Timing convention: same_day_load = %s", convention),
    sprintf("Parameters: %s", paste(names(gains), "=", format_number(gains),
                                     collapse = ", ")),
    sprintf("Time constants: %s", paste(sprintf(
      "%s = %s days (half-life %s days)", names(taus),
      format_number(taus), format_number(half_life(taus))
    ), collapse = ", "))
  )
}
