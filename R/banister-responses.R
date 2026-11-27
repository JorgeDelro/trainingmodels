#' Response to a single training session
#'
#' Computes the effect on predicted performance of one unit of load on the
#' days after a single session (the influence curve), the time until that
#' effect becomes positive and the time until it is largest (MODELS.md, M-05).
#' Nothing is fitted: the parameters are given by the user.
#'
#' @section Formula:
#' The effect \eqn{u} days after one unit of load is
#' \deqn{L(u) = k_1\,e^{-u/\tau_1} - k_2\,e^{-u/\tau_2}}{L(u) = k1 exp(-u/tau1) - k2 exp(-u/tau2)}
#' for the two-component model, and \eqn{k_1\,e^{-u/\tau_1}}{k1 exp(-u/tau1)}
#' for the fitness-only model. For \eqn{\tau_1 > \tau_2}{tau1 > tau2},
#' \deqn{\mathrm{time\_to\_recover} = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}
#'   \ln\frac{k_2}{k_1}, \qquad
#'   \mathrm{time\_to\_peak} = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}
#'   \ln\frac{k_2 \tau_1}{k_1 \tau_2},}{time_to_recover =
#'   tau1 tau2 / (tau1 - tau2) * log(k2 / k1), time_to_peak =
#'   tau1 tau2 / (tau1 - tau2) * log(k2 tau1 / (k1 tau2)),}
#' and `peak_effect` is \eqn{L} at `time_to_peak`. These are \eqn{t_n} and
#' \eqn{t_g} of Clarke & Skiba (2013) and Busso & Chalencon (2023); they are
#' named in words because Morton et al. (1990) use \eqn{t_n} for a different
#' quantity, the `time_of_minimum` of [constant_training()] (DECISIONS.md,
#' D-026).
#'
#' @section Timing convention:
#' The times do not depend on the convention. Only the effect on the day of
#' the session (day 0 of `curve`) does: \eqn{k_1 - k_2}{k1 - k2} with
#' `same_day_load = "include"`, 0 with `"exclude"` (the default, D-012).
#' From day 1 on, both conventions give \eqn{L(u)}.
#'
#' @section When the times are NA:
#' The times are `NA` when they do not exist (D-026):
#'
#' * `time_to_recover` is `NA` when \eqn{k_2 \le k_1}{k2 <= k1}: the effect is
#'   positive from the first day after the session, so there is nothing to
#'   recover from.
#' * `time_to_peak` and `peak_effect` are `NA` when
#'   \eqn{k_2 \tau_1 \le k_1 \tau_2}{k2 tau1 <= k1 tau2}: the effect is
#'   largest right after the session and only decreases.
#' * Both are `NA` when \eqn{k_1 = 0}{k1 = 0} (the effect is never positive),
#'   when \eqn{\tau_1 \le \tau_2}{tau1 <= tau2} (fatigue does not fade faster
#'   than fitness), and for the fitness-only model (there is no fatigue).
#'
#' @inheritParams simulate_banister
#' @param days Last day of the curve, a single whole number `>= 1`. The curve
#'   runs from day 0 (the day of the session) to `days`.
#'
#' @return A list of class `"session_response"` with the elements
#'   * `curve`: a data frame with the columns `day` (0 to `days`) and
#'     `effect` (effect on predicted performance per unit of load);
#'   * `time_to_recover`, `time_to_peak` (days) and `peak_effect` (per unit
#'     of load), each a number or `NA`;
#'   * `model`, `same_day_load`, `days` and `parameters`: the arguments used.
#'
#' @references
#' Clarke DC, Skiba PF (2013). Rationale and resources for teaching the
#' mathematical modeling of athletic training and performance. *Advances in
#' Physiology Education*, 37, 134-152.
#'
#' Busso T, Chalencon S (2023). Validity and accuracy of impulse-response
#' models for modeling and predicting training effects on performance of
#' swimmers. *Medicine & Science in Sports & Exercise*, 55(7), 1274-1285.
#'
#' Ceddia D, Bondell H, Taylor P (2025). Mathematical modelling and
#' optimisation of athletic performance: tapering and periodisation.
#' arXiv:2505.20859 (preprint).
#'
#' @seealso [simulate_banister()], [constant_training()], [half_life()].
#'
#' @examples
#' # Parameters of Morton et al. (1990)
#' r <- session_response(k1 = 1, tau1 = 45, k2 = 2, tau2 = 15)
#' r
#' head(r$curve)
#'
#' # Fit of Clarke & Skiba (2013)
#' session_response(k1 = 0.18258, tau1 = 35.821, k2 = 0.23016, tau2 = 21.340)
#'
#' @export
session_response <- function(k1, tau1, k2 = NULL, tau2 = NULL,
                             model = c("two_component", "fitness_only"),
                             days = 60,
                             same_day_load = c("exclude", "include")) {
  model <- check_choice(model, c("two_component", "fitness_only"), "model")
  same_day_load <- check_choice(same_day_load, c("exclude", "include"),
                                "same_day_load")
  parameters <- check_banister_parameters(model, k1, tau1, k2, tau2)
  days <- check_days(days)

  u <- 0:days
  effect <- parameters[["k1"]] * exp(-u / parameters[["tau1"]])
  if (model == "two_component") {
    effect <- effect - parameters[["k2"]] * exp(-u / parameters[["tau2"]])
  }
  if (same_day_load == "exclude") effect[1L] <- 0

  times <- session_times(model, parameters)
  structure(list(
    curve = data.frame(day = u, effect = effect),
    time_to_recover = times[["time_to_recover"]],
    time_to_peak = times[["time_to_peak"]],
    peak_effect = times[["peak_effect"]],
    model = model, same_day_load = same_day_load, days = days,
    parameters = parameters
  ), class = "session_response")
}

#' @rdname print.banister_sim
#' @export
print.session_response <- function(x, ...) {
  cat(sprintf("<session_response> Response to a single session: %s\n",
              model_label(x$model)))
  cat(banister_header(x$parameters, x$same_day_load), sep = "\n")
  cat(sprintf("Time to recover: %s\n",
              format_time(x$time_to_recover, recover_reason(x))))
  peak <- format_time(x$time_to_peak, peak_reason(x))
  if (!is.na(x$peak_effect)) {
    peak <- sprintf("%s (effect %s per unit of load)", peak,
                    format_number(x$peak_effect))
  }
  cat(sprintf("Time to peak: %s\n", peak))
  cat(sprintf("Curve: days 0 to %s in $curve; day 0 is the day of the session.\n",
              format(x$days)))
  invisible(x)
}

#' Response to constant daily training
#'
#' Computes fitness, fatigue and predicted performance when the same load is
#' done every day from day 1, with the closed forms of Morton et al. (1990,
#' Eqs. 6, 9-11), the asymptote of predicted performance and the day of
#' poorest performance (MODELS.md, M-04). Nothing is fitted: the parameters
#' are given by the user. The initial state is 0.
#'
#' @section Formula:
#' For a daily load \eqn{T} and the time constant \eqn{\tau} of either
#' component,
#' \deqn{g_{inc}(t) = T\,\frac{1 - e^{-t/\tau}}{1 - e^{-1/\tau}}, \qquad
#'   g_{exc}(t) = T\,e^{-1/\tau}\,\frac{1 - e^{-(t-1)/\tau}}{1 - e^{-1/\tau}}}{g_inc(t) =
#'   T (1 - exp(-t/tau)) / (1 - exp(-1/tau)), g_exc(t) =
#'   T exp(-1/tau) (1 - exp(-(t-1)/tau)) / (1 - exp(-1/tau))}
#' under `same_day_load = "include"` and `"exclude"` (the default, D-012).
#' These equal [simulate_banister()] on a series of constant load.
#'
#' @section Asymptote:
#' The asymptote is the predicted performance as days grow. It depends on
#' the convention: since \eqn{g_{exc}(t) = g_{inc}(t) - T}{g_exc(t) = g_inc(t) - T},
#' the "exclude" asymptote is the "include" one minus
#' \eqn{(k_1 - k_2)\,T}{(k1 - k2) T}:
#' \deqn{p_{inc}(\infty) = p_0 + \frac{k_1 T}{1 - e^{-1/\tau_1}} -
#'   \frac{k_2 T}{1 - e^{-1/\tau_2}}, \qquad
#'   p_{exc}(\infty) = p_0 + \frac{k_1 T e^{-1/\tau_1}}{1 - e^{-1/\tau_1}} -
#'   \frac{k_2 T e^{-1/\tau_2}}{1 - e^{-1/\tau_2}}.}{p_inc(inf) =
#'   p0 + k1 T / (1 - exp(-1/tau1)) - k2 T / (1 - exp(-1/tau2)), p_exc(inf) =
#'   p0 + k1 T exp(-1/tau1) / (1 - exp(-1/tau1)) -
#'   k2 T exp(-1/tau2) / (1 - exp(-1/tau2)).}
#'
#' @section Time of minimum:
#' The day of poorest performance (Morton et al. 1990, Eq. 10; their
#' \eqn{t_n}, named in words here, D-026) is
#' \deqn{\mathrm{time\_of\_minimum} = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}
#'   \ln\frac{\tau_1 k_2 (1 - e^{-1/\tau_1})}{\tau_2 k_1 (1 - e^{-1/\tau_2})},}{time_of_minimum =
#'   tau1 tau2 / (tau1 - tau2) *
#'   log(tau1 k2 (1 - exp(-1/tau1)) / (tau2 k1 (1 - exp(-1/tau2)))),}
#' the same under both conventions. It is a continuous time: the day with the
#' lowest predicted value in `curve` is the nearest whole day.
#'
#' `time_of_minimum` is `NA` when there is no minimum: when
#' \eqn{\tau_1 \le \tau_2}{tau1 <= tau2}, when the argument of the logarithm
#' is \eqn{\le 1}{<= 1} (fatigue is too small for performance to dip), when
#' \eqn{k_1 = 0}{k1 = 0} (performance only falls), and for the fitness-only
#' model (performance only rises).
#'
#' @inheritParams simulate_banister
#' @param load Daily training load, a single finite number `> 0`, done every
#'   day from day 1.
#' @param days Last day of the curve, a single whole number `>= 1`.
#'
#' @return A list of class `"constant_training"` with the elements
#'   * `curve`: a data frame with the columns `day` (1 to `days`), `fitness`,
#'     `fatigue` (`NA` for the fitness-only model) and `predicted`;
#'   * `asymptote`: predicted performance as days grow;
#'   * `time_of_minimum`: day of poorest performance, or `NA`;
#'   * `load`, `model`, `same_day_load`, `days` and `parameters`: the
#'     arguments used.
#'
#' @references
#' Morton RH, Fitz-Clarke JR, Banister EW (1990). Modeling human performance
#' in running. *Journal of Applied Physiology*, 69(3), 1171-1177.
#'
#' @seealso [simulate_banister()], [session_response()], [half_life()].
#'
#' @examples
#' # Morton et al. (1990): load 100 every day
#' constant_training(100, k1 = 1, tau1 = 45, k2 = 2, tau2 = 15,
#'                   same_day_load = "include")
#'
#' @export
constant_training <- function(load, k1, tau1, k2 = NULL, tau2 = NULL, p0 = 0,
                              model = c("two_component", "fitness_only"),
                              days = 100,
                              same_day_load = c("exclude", "include")) {
  load <- check_number(load, "load", min = 0, strict = TRUE)
  model <- check_choice(model, c("two_component", "fitness_only"), "model")
  same_day_load <- check_choice(same_day_load, c("exclude", "include"),
                                "same_day_load")
  parameters <- check_banister_parameters(model, k1, tau1, k2, tau2, p0)
  days <- check_days(days)
  two_component <- model == "two_component"

  t <- seq_len(days)
  # Closed form of M-04 and its limit as t grows.
  component <- function(tau) {
    decay <- exp(-1 / tau)
    if (same_day_load == "include") {
      list(curve = load * (1 - exp(-t / tau)) / (1 - decay),
           limit = load / (1 - decay))
    } else {
      list(curve = load * decay * (1 - exp(-(t - 1) / tau)) / (1 - decay),
           limit = load * decay / (1 - decay))
    }
  }
  k1 <- parameters[["k1"]]
  tau1 <- parameters[["tau1"]]
  fitness <- component(tau1)
  predicted <- parameters[["p0"]] + k1 * fitness$curve
  asymptote <- parameters[["p0"]] + k1 * fitness$limit
  fatigue <- rep(NA_real_, days)
  time_of_minimum <- NA_real_
  if (two_component) {
    k2 <- parameters[["k2"]]
    tau2 <- parameters[["tau2"]]
    h <- component(tau2)
    fatigue <- h$curve
    predicted <- predicted - k2 * h$curve
    asymptote <- asymptote - k2 * h$limit
    if (tau1 > tau2 && k1 > 0) {
      ratio <- tau1 * k2 * (1 - exp(-1 / tau1)) /
        (tau2 * k1 * (1 - exp(-1 / tau2)))
      if (ratio > 1) {
        time_of_minimum <- tau1 * tau2 / (tau1 - tau2) * log(ratio)
      }
    }
  }

  structure(list(
    curve = data.frame(day = t, fitness = fitness$curve, fatigue = fatigue,
                       predicted = predicted),
    asymptote = asymptote, time_of_minimum = time_of_minimum,
    load = load, model = model, same_day_load = same_day_load, days = days,
    parameters = parameters
  ), class = "constant_training")
}

#' @rdname print.banister_sim
#' @export
print.constant_training <- function(x, ...) {
  cat(sprintf(
    "<constant_training> Constant daily training of %s: %s\n",
    format_number(x$load), model_label(x$model)
  ))
  cat(banister_header(x$parameters, x$same_day_load), sep = "\n")
  cat(sprintf("Asymptote of predicted performance: %s\n",
              format(x$asymptote, digits = 6)))
  cat(sprintf("Time of minimum: %s\n",
              format_time(x$time_of_minimum, minimum_reason(x))))
  cat(sprintf("Curve: days 1 to %s in $curve.\n", format(x$days)))
  invisible(x)
}

# Internal helpers --------------------------------------------------------------

# time_to_recover, time_to_peak and peak_effect of M-05, NA when they do not
# exist (D-026).
session_times <- function(model, parameters) {
  out <- c(time_to_recover = NA_real_, time_to_peak = NA_real_,
           peak_effect = NA_real_)
  if (model == "fitness_only") return(out)
  k1 <- parameters[["k1"]]
  k2 <- parameters[["k2"]]
  tau1 <- parameters[["tau1"]]
  tau2 <- parameters[["tau2"]]
  if (tau1 <= tau2 || k1 == 0) return(out)
  scale <- tau1 * tau2 / (tau1 - tau2)
  if (k2 > k1) {
    out[["time_to_recover"]] <- scale * log(k2 / k1)
  }
  if (k2 * tau1 > k1 * tau2) {
    peak <- scale * log(k2 * tau1 / (k1 * tau2))
    out[["time_to_peak"]] <- peak
    out[["peak_effect"]] <- k1 * exp(-peak / tau1) - k2 * exp(-peak / tau2)
  }
  out
}

format_time <- function(value, reason) {
  if (is.na(value)) {
    sprintf("NA (%s)", reason)
  } else {
    sprintf("%s days", format_number(value))
  }
}

# Why a time is NA; the order follows the checks of session_times().
recover_reason <- function(x) {
  p <- x$parameters
  if (x$model == "fitness_only") return("no fatigue component")
  if (p[["tau1"]] <= p[["tau2"]]) return("tau1 <= tau2")
  if (p[["k1"]] == 0) return("k1 = 0: the effect is never positive")
  "k2 <= k1: the effect is positive from the first day"
}

peak_reason <- function(x) {
  p <- x$parameters
  if (x$model == "fitness_only") return("no fatigue component")
  if (p[["tau1"]] <= p[["tau2"]]) return("tau1 <= tau2")
  if (p[["k1"]] == 0) return("k1 = 0: the effect is never positive")
  "k2 * tau1 <= k1 * tau2: the effect only decreases after the session"
}

minimum_reason <- function(x) {
  p <- x$parameters
  if (x$model == "fitness_only") return("no fatigue component")
  if (p[["tau1"]] <= p[["tau2"]]) return("tau1 <= tau2")
  if (p[["k1"]] == 0) return("k1 = 0: performance only falls")
  "fatigue too small for performance to dip"
}
