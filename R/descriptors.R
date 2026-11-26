#' Session RPE load
#'
#' Computes the session rating of perceived exertion (RPE) load of Foster
#' (1998) and Foster et al. (2001): the RPE of the session multiplied by its
#' duration in minutes (MODELS.md, M-10).
#'
#' \deqn{w = \mathrm{RPE} \times D}{w = RPE x D}
#'
#' @section Collecting the data:
#' * **RPE** is rated on the 0-10 category-ratio scale: one global rating for
#'   the whole session, asked about 30 minutes after it ends.
#' * **Duration** is the duration in minutes of the entire session, including
#'   warm-up, cool-down and recovery intervals.
#'
#' Several sessions on the same day are summed when the loads are passed to
#' [as_daily_load()].
#'
#' Session RPE load is in arbitrary units. Comparing it across athletes needs
#' care.
#'
#' @param rpe Numeric vector of session RPE values, each between 0 and 10 or
#'   `NA`.
#' @param duration Numeric vector of session durations in minutes, each
#'   `>= 0` or `NA`. Must have the same length as `rpe`, or one of the two
#'   must have length 1.
#'
#' @return A numeric vector, `rpe * duration`. `NA` in either argument gives
#'   `NA`.
#'
#' @references
#' Foster C (1998). Monitoring training in athletes with reference to
#' overtraining syndrome. *Medicine and Science in Sports and Exercise*,
#' 30(7), 1164-1168.
#'
#' Foster C, Florhaug JA, Franklin J, et al. (2001). A new approach to
#' monitoring exercise training. *Journal of Strength and Conditioning
#' Research*, 15(1), 109-115.
#'
#' @seealso [as_daily_load()] to build the daily series, [rolling_load()] and
#'   [monotony_strain()] to describe it.
#'
#' @examples
#' # The week of Foster (1998), Table 1
#' srpe_load(rpe = c(5, 7, 2, 6, 7, 2, 7),
#'           duration = c(180, 120, 20, 90, 75, 20, 120))
#'
#' @export
srpe_load <- function(rpe, duration) {
  rpe <- check_session_values(rpe, "rpe")
  duration <- check_session_values(duration, "duration")
  if (length(rpe) != length(duration) && length(rpe) != 1L &&
      length(duration) != 1L) {
    stop(sprintf(
      "`rpe` (length %d) and `duration` (length %d) must have the same length, or one of them length 1.",
      length(rpe), length(duration)
    ), call. = FALSE)
  }
  bad <- which(!is.na(rpe) & (rpe < 0 | rpe > 10))[1L]
  if (!is.na(bad)) {
    stop(sprintf(
      "`rpe` must be between 0 and 10 or NA; position %d is %s.",
      bad, format(rpe[bad])
    ), call. = FALSE)
  }
  bad <- which(!is.na(duration) & duration < 0)[1L]
  if (!is.na(bad)) {
    stop(sprintf(
      "`duration` must be >= 0 minutes or NA; position %d is %s.",
      bad, format(duration[bad])
    ), call. = FALSE)
  }
  rpe * duration
}

#' Rolling training load
#'
#' Computes, for every day, the sum and the mean of the daily loads over a
#' window of `window` days, within each athlete (MODELS.md, M-11).
#'
#' @section Formula:
#' For the daily loads \eqn{w(1), \dots, w(T)}{w(1), ..., w(T)} of one athlete
#' and a window of \eqn{k} days:
#'
#' * `same_day_load = "include"` (the default): the window ends on the
#'   current day,
#'   \deqn{S(t) = \sum_{j = t-k+1}^{t} w(j),}{S(t) = w(t-k+1) + ... + w(t),}
#'   defined for \eqn{t \ge k}{t >= k};
#' * `same_day_load = "exclude"`: the window ends on the previous day,
#'   \deqn{S(t) = \sum_{j = t-k}^{t-1} w(j),}{S(t) = w(t-k) + ... + w(t-1),}
#'   defined for \eqn{t \ge k + 1}{t >= k + 1}. This is the form of Carey et
#'   al. (2017, Eq. 1).
#'
#' The rolling mean is \eqn{S(t) / k}. The two options are related by
#' "exclude" on day \eqn{t} = "include" on day \eqn{t - 1}.
#'
#' @section Timing option and default:
#' The default is `same_day_load = "include"` (DECISIONS.md, D-021). This
#' differs from the impulse-response models, whose default is "exclude"
#' (D-012).
#'
#' @section Missing and rest days:
#' A day with a missing load makes every window that contains it `NA`
#' (D-016); missing loads are never filled. Windows that do not fit in the
#' series (the first \eqn{k - 1} days with "include", the first \eqn{k} with
#' "exclude") are `NA`: there are no partial windows. Rest days count as load
#' 0. Days added by [as_daily_load()] count as rest or as missing according to
#' its `gaps` argument.
#'
#' @section Acute:chronic workload ratio:
#' Ratios of rolling loads and EWMA-based loads are not provided here: see the
#' ACWR package (DECISIONS.md, D-019).
#'
#' @param x A `daily_load` object, from [as_daily_load()]. It is checked
#'   first; an object changed after it was built (for example by subsetting)
#'   must be rebuilt with [as_daily_load()].
#' @param window Length of the window in days, a single whole number `>= 1`.
#' @param same_day_load Whether the window ends on the current day
#'   (`"include"`, the default) or on the previous day (`"exclude"`).
#'
#' @return A data frame with one row per row of `x`, in the same order, and
#'   the columns `athlete`, `date`, `load`, `rolling_sum` and `rolling_mean`.
#'   The attributes `window` and `same_day_load` record the arguments used.
#'
#' @references
#' Carey DL, Blanch P, Ong KL, et al. (2017). Training loads and injury risk
#' in Australian football: differing acute:chronic workload ratios influence
#' match injury risk. *British Journal of Sports Medicine*, 51(16), 1215-1220.
#'
#' @seealso [monotony_strain()], [srpe_load()], [as_daily_load()].
#'
#' @examples
#' x <- as_daily_load(
#'   data.frame(date = as.Date("2026-01-01") + 0:9,
#'              load = c(300, 0, 450, 500, 0, 0, 620, 410, 380, 0)),
#'   date = "date", load = "load"
#' )
#' rolling_load(x, window = 3)
#' rolling_load(x, window = 3, same_day_load = "exclude")
#'
#' @export
rolling_load <- function(x, window = 7,
                         same_day_load = c("include", "exclude")) {
  validate_daily_load(x)
  check_window(window, min = 1)
  same_day_load <- check_same_day_load(same_day_load)

  windows <- daily_windows(x, window, same_day_load)
  rolling_sum <- vapply(windows, function(w) {
    if (is.null(w) || anyNA(w)) NA_real_ else sum(w)
  }, numeric(1))

  out <- data.frame(athlete = x$athlete, date = x$date, load = x$load,
                    rolling_sum = rolling_sum,
                    rolling_mean = rolling_sum / window,
                    stringsAsFactors = FALSE)
  structure(out, window = window, same_day_load = same_day_load)
}

#' Training monotony and strain
#'
#' Computes Foster's (1998) training monotony and strain for every day, over
#' a rolling window of `window` days (7 by default), within each athlete
#' (MODELS.md, M-12).
#'
#' @section Formula:
#' For the loads of the window,
#' \deqn{\mathrm{monotony} = \frac{\mathrm{mean\ load}}{\mathrm{SD\ of\ the\ loads}},
#'   \qquad \mathrm{strain} = \mathrm{window\ load} \times \mathrm{monotony},}{
#'   monotony = mean load / SD of the loads,
#'   strain = window load x monotony,}
#' where the window load is the sum of the loads and the SD is the sample
#' standard deviation (divisor \eqn{k - 1}). Foster (1998) defines them over a
#' week; the package uses a rolling window computed every day (D-022). The
#' window is the one of [rolling_load()] (MODELS.md, M-11).
#'
#' @section Timing option and default:
#' With `same_day_load = "include"` (the default) the window ends on the
#' current day; with `"exclude"` it ends on the previous day. The default
#' differs from the impulse-response models, whose default is "exclude"
#' (DECISIONS.md, D-021 and D-012).
#'
#' @section Missing, rest and equal days:
#' * A day with a missing load makes every window that contains it `NA` in
#'   every result column (D-016). Windows that do not fit in the series are
#'   `NA`: there are no partial windows.
#' * Rest days count as load 0. Foster (1998) does not say how rest days are
#'   treated; the result depends on this choice.
#' * When all loads of the window are equal (for example seven rest days),
#'   `sd_load` is 0 and `monotony` and `strain` are `NA` (D-022). Equality is
#'   tested on the loads themselves, not on the computed standard deviation.
#'
#' Monotony divides by a standard deviation, so it is unstable when the days
#' of the window are similar. The article "Monotony and strain" on the
#' package website discusses its limitations.
#'
#' @section Acute:chronic workload ratio:
#' Ratios of rolling loads and EWMA-based loads are not provided here: see the
#' ACWR package (DECISIONS.md, D-019).
#'
#' @inheritParams rolling_load
#' @param window Length of the window in days, a single whole number `>= 2`.
#'
#' @return A data frame with one row per row of `x`, in the same order, and
#'   the columns `athlete`, `date`, `load`, `window_load`, `mean_load`,
#'   `sd_load`, `monotony` and `strain`. The attributes `window` and
#'   `same_day_load` record the arguments used.
#'
#' @references
#' Foster C (1998). Monitoring training in athletes with reference to
#' overtraining syndrome. *Medicine and Science in Sports and Exercise*,
#' 30(7), 1164-1168.
#'
#' @seealso [rolling_load()], [srpe_load()], [as_daily_load()].
#'
#' @examples
#' # The week of Foster (1998), Table 1
#' week <- data.frame(
#'   date = as.Date("2026-01-04") + 0:6,
#'   load = srpe_load(rpe = c(5, 7, 2, 6, 7, 2, 7),
#'                    duration = c(180, 120, 20, 90, 75, 20, 120))
#' )
#' x <- as_daily_load(week, date = "date", load = "load")
#' monotony_strain(x)
#'
#' @export
monotony_strain <- function(x, window = 7,
                            same_day_load = c("include", "exclude")) {
  validate_daily_load(x)
  check_window(window, min = 2)
  same_day_load <- check_same_day_load(same_day_load)

  windows <- daily_windows(x, window, same_day_load)
  stats <- lapply(windows, function(w) {
    if (is.null(w) || anyNA(w)) {
      return(rep(NA_real_, 5L))
    }
    total <- sum(w)
    mean_load <- mean(w)
    # Equal loads: the SD is 0 by definition. sd() of identical decimals
    # is not guaranteed to be exactly 0 on every platform (D-022).
    if (min(w) == max(w)) {
      return(c(total, mean_load, 0, NA_real_, NA_real_))
    }
    sd_load <- stats::sd(w)
    monotony <- mean_load / sd_load
    c(total, mean_load, sd_load, monotony, total * monotony)
  })
  stats <- do.call(rbind, stats)

  out <- data.frame(athlete = x$athlete, date = x$date, load = x$load,
                    window_load = stats[, 1L], mean_load = stats[, 2L],
                    sd_load = stats[, 3L], monotony = stats[, 4L],
                    strain = stats[, 5L], stringsAsFactors = FALSE)
  structure(out, window = window, same_day_load = same_day_load)
}

# Internal helpers --------------------------------------------------------------

# For every row of a valid daily_load, the loads of its window, or NULL when
# the window does not fit in that athlete's series. Rows of one athlete are
# contiguous and consecutive (checked by validate_daily_load()), so positions
# within an athlete are days.
daily_windows <- function(x, window, same_day_load) {
  windows <- vector("list", nrow(x))
  for (a in unique(x$athlete)) {
    rows <- which(x$athlete == a)
    load <- x$load[rows]
    for (t in seq_along(rows)) {
      last <- if (same_day_load == "include") t else t - 1L
      first <- last - window + 1L
      if (first >= 1L) {
        windows[[rows[t]]] <- load[first:last]
      }
    }
  }
  windows
}

check_window <- function(window, min) {
  if (!is.numeric(window) || length(window) != 1L || is.na(window) ||
      !is.finite(window) || window != round(window) || window < min) {
    stop(sprintf("`window` must be a single whole number >= %d.", min),
         call. = FALSE)
  }
}

check_same_day_load <- function(same_day_load) {
  if (identical(same_day_load, c("include", "exclude"))) return("include")
  if (!is.character(same_day_load) || length(same_day_load) != 1L ||
      is.na(same_day_load) ||
      !same_day_load %in% c("include", "exclude")) {
    stop("`same_day_load` must be \"include\" or \"exclude\".", call. = FALSE)
  }
  same_day_load
}

# Session-level numeric input for srpe_load(): numeric, finite or NA.
check_session_values <- function(x, arg) {
  # An all-NA logical vector (such as a single NA) is accepted as numeric NA.
  if (is.logical(x) && all(is.na(x))) x <- rep(NA_real_, length(x))
  if (!is.numeric(x) || is.factor(x)) {
    stop(sprintf("`%s` must be numeric, not %s.", arg, class(x)[1L]),
         call. = FALSE)
  }
  x <- as.double(x)
  bad <- which(is.nan(x) | is.infinite(x))[1L]
  if (!is.na(bad)) {
    stop(sprintf("`%s` must hold finite values or NA; position %d is %s.",
                 arg, bad, format(x[bad])), call. = FALSE)
  }
  x
}
