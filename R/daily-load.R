#' Build a daily training-load series
#'
#' Converts a data frame with one row per training session (or per day) into
#' a complete daily calendar with one row per athlete and day. This is the
#' single entry point for every analysis in the package: descriptors and
#' impulse-response models take a `daily_load` object.
#'
#' @section Day states:
#' Every day has exactly one of three states (DECISIONS.md, D-015):
#'
#' * **training**: the load of the day is greater than 0;
#' * **rest**: the load of the day is 0;
#' * **missing**: the load of the day is not available (`NA`).
#'
#' Sessions on the same day are summed. If any session of a day has an `NA`
#' load, the whole day is `NA` and its state is "missing": a missing load is
#' never silently replaced (D-016).
#'
#' @section Gap rule:
#' Each athlete's calendar runs from their own first to their own last date.
#' Days in between that have no row are added and marked `filled = TRUE`.
#' By default (`gaps = "rest"`) they are treated as rest days with load 0;
#' with `gaps = "missing"` they get load `NA` and state "missing" (D-015).
#' The calendar ends at the athlete's last row: rest days after the last
#' session are not added, so trailing rest days must be given as rows with
#' load 0 to be included.
#' A message reports how many days were filled. Whatever `gaps` is, a warning
#' is given for every run of more than `max_gap` consecutive filled days,
#' because a long run without data is as likely to be missing data as rest.
#'
#' @section Several athletes and load columns:
#' A data file may hold several athletes (identified by the column named in
#' `athlete`) and several load columns; each call uses one load column
#' (D-017). Its name is kept in the attribute `load_name`.
#'
#' @param data A data frame with one row per session (or per day).
#' @param date Name of the date column. The column must be of class `Date`,
#'   or character to be parsed with `date_format`. A `Date` with a fraction
#'   of a day is floored to the day. Date-times (`POSIXct`) are
#'   rejected: convert them with [as.Date()] first, choosing the time zone.
#' @param load Name of the load column: numeric, `>= 0` or `NA`. A column
#'   that is entirely `NA` (an empty column in a CSV file, read as logical)
#'   is accepted as numeric `NA`.
#' @param athlete Name of the athlete identifier column, or `NULL` (the
#'   default) for a single athlete, who is labelled `"1"`.
#' @param performance Name of a numeric performance column, or `NULL`. At most
#'   one distinct non-`NA` value is allowed per athlete and day. An entirely
#'   `NA` column is accepted, as for `load`.
#' @param gaps How to treat days with no row between an athlete's first and
#'   last date: `"rest"` (load 0, the default) or `"missing"` (load `NA`).
#' @param max_gap A single non-negative whole number. A warning is given for
#'   each run of more than `max_gap` consecutive days without a row.
#' @param date_format Format used to parse a character date column, as in
#'   [strptime()]. The default `NULL` accepts ISO dates (`"%Y-%m-%d"`) only.
#'   Any parsed year before 1900 or after 2100 is an error, which catches
#'   two-digit years read with `"%Y"`.
#'
#' @return An object of class `c("daily_load", "data.frame")` with one row per
#'   athlete and day, sorted by athlete and date, and the columns:
#'
#'   * `athlete` (character);
#'   * `date` (`Date`), consecutive within each athlete;
#'   * `load` (numeric), the sum of the day's sessions;
#'   * `status` (factor with levels `"training"`, `"rest"`, `"missing"`);
#'   * `n_sessions` (integer), the number of rows in `data` for that day, 0
#'     for filled days;
#'   * `filled` (logical), `TRUE` for days that had no row;
#'   * `performance` (numeric), only if `performance` was given.
#'
#'   The attributes `gaps` and `load_name` record the gap option used and the
#'   name of the load column.
#'
#' @seealso [print.daily_load()], [summary.daily_load()].
#'
#' @examples
#' sessions <- data.frame(
#'   athlete = c("A", "A", "A", "A", "B", "B"),
#'   date = c("2026-01-01", "2026-01-01", "2026-01-02", "2026-01-05",
#'            "2026-01-03", "2026-01-04"),
#'   srpe = c(300, 150, 0, NA, 420, 380),
#'   jump = c(41.2, NA, NA, 40.5, NA, 38.9)
#' )
#'
#' x <- as_daily_load(sessions, date = "date", load = "srpe",
#'                    athlete = "athlete", performance = "jump")
#' x
#' summary(x)
#'
#' # Days without a row treated as missing instead of rest
#' as_daily_load(sessions, date = "date", load = "srpe",
#'               athlete = "athlete", gaps = "missing")
#'
#' @export
as_daily_load <- function(data, date, load, athlete = NULL,
                          performance = NULL, gaps = c("rest", "missing"),
                          max_gap = 7, date_format = NULL) {
  # Arguments -----------------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  gaps <- check_gaps(gaps)
  if (!is.numeric(max_gap) || length(max_gap) != 1L || is.na(max_gap) ||
      !is.finite(max_gap) || max_gap < 0 || max_gap != round(max_gap)) {
    stop("`max_gap` must be a single non-negative whole number.",
         call. = FALSE)
  }
  if (!is.null(date_format) &&
      (!is.character(date_format) || length(date_format) != 1L ||
       is.na(date_format))) {
    stop("`date_format` must be NULL or a single string, such as ",
         "\"%d/%m/%Y\".", call. = FALSE)
  }
  check_column(data, date, "date")
  check_column(data, load, "load")
  if (!is.null(athlete)) check_column(data, athlete, "athlete")
  if (!is.null(performance)) check_column(data, performance, "performance")
  if (nrow(data) == 0L) {
    stop("`data` has no rows.", call. = FALSE)
  }

  # Columns -------------------------------------------------------------------
  dates <- parse_dates(data[[date]], date, date_format)
  loads <- check_numeric(data[[load]], load, "load", negative = FALSE)
  ids <- if (is.null(athlete)) {
    rep("1", nrow(data))
  } else {
    athlete_ids(data[[athlete]], athlete)
  }
  perf <- if (is.null(performance)) {
    NULL
  } else {
    check_numeric(data[[performance]], performance, "performance",
                  negative = TRUE)
  }

  # One calendar per athlete --------------------------------------------------
  pieces <- lapply(sort(unique(ids), method = "radix"), function(a) {
    rows <- which(ids == a)
    daily_calendar(a, dates[rows], loads[rows],
                   if (is.null(perf)) NULL else perf[rows],
                   gaps, performance)
  })
  out <- data.frame(
    athlete = unlist(lapply(pieces, `[[`, "athlete"), use.names = FALSE),
    date = do.call(c, lapply(pieces, `[[`, "date")),
    load = unlist(lapply(pieces, `[[`, "load"), use.names = FALSE),
    stringsAsFactors = FALSE
  )
  out$status <- day_status(out$load)
  out$n_sessions <- unlist(lapply(pieces, `[[`, "n_sessions"),
                           use.names = FALSE)
  out$filled <- out$n_sessions == 0L
  if (!is.null(perf)) {
    out$performance <- unlist(lapply(pieces, `[[`, "performance"),
                              use.names = FALSE)
  }

  # Report filled days --------------------------------------------------------
  n_filled <- sum(out$filled)
  if (n_filled > 0L) {
    message(sprintf(
      "Filled %d %s without a row as %s (load %s).%s",
      n_filled, if (n_filled == 1L) "day" else "days", gaps,
      if (gaps == "rest") "0" else "NA",
      if (gaps == "rest") {
        " Use gaps = \"missing\" to treat filled days as missing."
      } else {
        ""
      }
    ))
  }
  runs <- filled_runs(out)
  long <- runs[runs$length > max_gap, , drop = FALSE]
  if (nrow(long) > 0L) {
    warning(
      sprintf("Runs of more than %d consecutive days without a row ", max_gap),
      "(check whether they are rest or missing data):\n",
      paste(sprintf("  athlete %s: %s to %s (%d days)", long$athlete,
                    format(long$first), format(long$last), long$length),
            collapse = "\n"),
      call. = FALSE
    )
  }

  structure(out, class = c("daily_load", "data.frame"), gaps = gaps,
            load_name = load)
}

#' Print a daily training-load series
#'
#' Prints a header (number of athletes, date range, number of days, counts by
#' day state and number of filled days) followed by the first rows.
#'
#' @param x A `daily_load` object, from [as_daily_load()].
#' @param n Number of rows to show.
#' @param ... Passed to [print.data.frame()].
#'
#' @return `x`, invisibly.
#'
#' @examples
#' x <- as_daily_load(
#'   data.frame(date = c("2026-01-01", "2026-01-03"), load = c(300, 250)),
#'   date = "date", load = "load"
#' )
#' print(x)
#'
#' @export
print.daily_load <- function(x, n = 10, ...) {
  status <- table(factor(x$status, levels = day_states))
  n_athletes <- length(unique(x$athlete))
  cat(sprintf(
    "<daily_load> %d %s, %s to %s, %d days\n",
    n_athletes, if (n_athletes == 1L) "athlete" else "athletes",
    format(min(x$date)), format(max(x$date)), nrow(x)
  ))
  cat(sprintf(
    "Days: %d training, %d rest, %d missing; %d filled (as %s)\n",
    status[["training"]], status[["rest"]], status[["missing"]],
    sum(x$filled), attr(x, "gaps")
  ))
  cat(sprintf("Load column: %s\n\n", attr(x, "load_name")))

  shown <- min(n, nrow(x))
  rows <- strip_daily_load(x)[seq_len(shown), , drop = FALSE]
  print(rows, ...)
  if (nrow(x) > shown) {
    cat(sprintf("# ... %d more rows\n", nrow(x) - shown))
  }
  invisible(x)
}

#' Summarise a daily training-load series by athlete
#'
#' @param object A `daily_load` object, from [as_daily_load()].
#' @param ... Not used.
#'
#' @return A data frame with one row per athlete and the columns `athlete`,
#'   `first_date`, `last_date`, `n_days`, `n_training`, `n_rest`,
#'   `n_missing`, `n_filled`, `longest_filled_run` (the longest run of
#'   consecutive filled days) and `n_performance` (days with a non-`NA`
#'   performance value; 0 if there is no performance column).
#'
#' @examples
#' x <- as_daily_load(
#'   data.frame(date = c("2026-01-01", "2026-01-03"), load = c(300, 250)),
#'   date = "date", load = "load"
#' )
#' summary(x)
#'
#' @export
summary.daily_load <- function(object, ...) {
  athletes <- unique(object$athlete)
  has_perf <- "performance" %in% names(object)
  rows <- lapply(athletes, function(a) {
    day <- object[object$athlete == a, , drop = FALSE]
    run <- rle(day$filled)
    data.frame(
      athlete = a,
      first_date = min(day$date),
      last_date = max(day$date),
      n_days = nrow(day),
      n_training = sum(day$status == "training"),
      n_rest = sum(day$status == "rest"),
      n_missing = sum(day$status == "missing"),
      n_filled = sum(day$filled),
      longest_filled_run = max(c(0L, run$lengths[run$values])),
      n_performance = if (has_perf) sum(!is.na(day$performance)) else 0L,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# Internal helpers --------------------------------------------------------------

day_states <- c("training", "rest", "missing")

check_gaps <- function(gaps) {
  if (identical(gaps, c("rest", "missing"))) return("rest")
  if (!is.character(gaps) || length(gaps) != 1L || is.na(gaps) ||
      !gaps %in% c("rest", "missing")) {
    stop("`gaps` must be \"rest\" or \"missing\".", call. = FALSE)
  }
  gaps
}

check_column <- function(data, name, arg) {
  if (!is.character(name) || length(name) != 1L || is.na(name)) {
    stop(sprintf("`%s` must be a single column name (a string).", arg),
         call. = FALSE)
  }
  if (!name %in% names(data)) {
    stop(sprintf("Column \"%s\" (argument `%s`) is not in `data`.", name, arg),
         call. = FALSE)
  }
}

parse_dates <- function(x, name, date_format) {
  if (inherits(x, "POSIXt")) {
    stop(sprintf(
      "Column \"%s\" is a date-time (POSIXct). Convert it to Date first, ",
      name
    ), "for example with as.Date(x, tz = \"Europe/Madrid\").", call. = FALSE)
  }
  if (is.factor(x)) x <- as.character(x)
  if (!inherits(x, "Date") && !is.character(x)) {
    stop(sprintf(
      "Column \"%s\" must be of class Date or character, not %s.",
      name, class(x)[1L]
    ), call. = FALSE)
  }
  first_na <- which(is.na(x))[1L]
  if (!is.na(first_na)) {
    stop(sprintf("Column \"%s\" has NA in row %d. Every row needs a date.",
                 name, first_na), call. = FALSE)
  }
  if (inherits(x, "Date")) {
    # A Date can hold a fraction of a day; only the day is kept.
    x <- structure(floor(unclass(x)), class = "Date")
  }
  if (is.character(x)) {
    fmt <- if (is.null(date_format)) "%Y-%m-%d" else date_format
    parsed <- as.Date(x, format = fmt)
    bad <- which(is.na(parsed))[1L]
    if (!is.na(bad)) {
      stop(sprintf(
        "Column \"%s\": the value \"%s\" in row %d cannot be read with the date format \"%s\".",
        name, x[bad], bad, fmt
      ), if (is.null(date_format)) " Set `date_format` for non-ISO dates.",
      call. = FALSE)
    }
    x <- parsed
  }
  year <- as.POSIXlt(x)$year + 1900L
  bad <- which(year < 1900L | year > 2100L)[1L]
  if (!is.na(bad)) {
    stop(sprintf(
      "Column \"%s\": row %d gives the date %s, with a year outside 1900-2100. Check `date_format` (\"%%Y\" needs a four-digit year).",
      name, bad, iso_date(x[bad])
    ), call. = FALSE)
  }
  x
}

check_numeric <- function(x, name, arg, negative) {
  # An empty column in a CSV is read as logical NA.
  if (is.logical(x) && all(is.na(x))) x <- rep(NA_real_, length(x))
  if (!is.numeric(x)) {
    stop(sprintf("Column \"%s\" (%s) must be numeric, not %s.",
                 name, arg, class(x)[1L]), call. = FALSE)
  }
  x <- as.double(x)
  bad <- which(is.nan(x) | is.infinite(x))[1L]
  if (!is.na(bad)) {
    stop(sprintf(
      "Column \"%s\" (%s) must hold finite values or NA; row %d is %s.",
      name, arg, bad, format(x[bad])
    ), call. = FALSE)
  }
  if (!negative) {
    bad <- which(x < 0)[1L]
    if (!is.na(bad)) {
      stop(sprintf(
        "Column \"%s\" (%s) has a negative value in row %d (%s). Loads must be >= 0 or NA.",
        name, arg, bad, format(x[bad])
      ), call. = FALSE)
    }
  }
  x
}

athlete_ids <- function(x, name) {
  first_na <- which(is.na(x))[1L]
  if (!is.na(first_na)) {
    stop(sprintf("Column \"%s\" (athlete) has NA in row %d.", name, first_na),
         call. = FALSE)
  }
  # Avoid scientific notation for numeric identifiers such as 100000.
  if (is.numeric(x) && all(x == round(x)) &&
      all(abs(x) <= .Machine$integer.max)) {
    x <- as.integer(x)
  }
  as.character(x)
}

# Builds the calendar of one athlete. `dates`, `loads` and `perf` are that
# athlete's rows of the input.
daily_calendar <- function(id, dates, loads, perf, gaps, perf_name) {
  first <- min(dates)
  days <- seq(first, max(dates), by = "day")
  pos <- as.integer(dates - first) + 1L

  n_sessions <- tabulate(pos, nbins = length(days))
  day_load <- rep(if (gaps == "rest") 0 else NA_real_, length(days))
  # rowsum() keeps NA, so a day with any NA session stays NA (D-016).
  sums <- rowsum(loads, pos, reorder = TRUE)
  day_load[as.integer(rownames(sums))] <- sums[, 1L]

  out <- list(athlete = rep(id, length(days)), date = days, load = day_load,
              n_sessions = n_sessions)

  if (!is.null(perf)) {
    day_perf <- rep(NA_real_, length(days))
    for (p in unique(pos[!is.na(perf)])) {
      values <- unique(perf[pos == p & !is.na(perf)])
      if (length(values) > 1L) {
        stop(sprintf(
          "Column \"%s\" (performance) has %d different values for athlete %s on %s: %s. Keep at most one per day.",
          perf_name, length(values), id, format(days[p]),
          paste(format(values), collapse = ", ")
        ), call. = FALSE)
      }
      day_perf[p] <- values
    }
    out$performance <- day_perf
  }
  out
}

day_status <- function(load) {
  status <- ifelse(is.na(load), "missing",
                   ifelse(load == 0, "rest", "training"))
  factor(status, levels = day_states)
}

# Runs of consecutive filled days: athlete, first and last date, length.
filled_runs <- function(x) {
  runs <- lapply(unique(x$athlete), function(a) {
    day <- x[x$athlete == a, , drop = FALSE]
    r <- rle(day$filled)
    end <- cumsum(r$lengths)
    start <- end - r$lengths + 1L
    keep <- r$values
    data.frame(athlete = rep(a, sum(keep)), first = day$date[start[keep]],
               last = day$date[end[keep]], length = r$lengths[keep],
               stringsAsFactors = FALSE)
  })
  do.call(rbind, runs)
}

strip_daily_load <- function(x) {
  attr(x, "gaps") <- NULL
  attr(x, "load_name") <- NULL
  class(x) <- "data.frame"
  x
}

# format() of a Date does not zero-pad years below 1000 on every platform
# (glibc gives "26-04-03"), so the date is written from its parts.
iso_date <- function(x) {
  lt <- as.POSIXlt(x)
  sprintf("%04d-%02d-%02d", lt$year + 1900L, lt$mon + 1L, lt$mday)
}
