# Internal validator for daily_load objects (issue #4; DECISIONS.md, A-011).
#
# A daily_load is a data frame, so subsetting, reordering or assigning to it
# keeps the class without checking anything. Every function that takes a
# daily_load calls validate_daily_load() first, and stops on the first
# invariant of as_daily_load() that no longer holds.

validate_daily_load <- function(x, arg = "x") {
  if (!inherits(x, "daily_load") || !is.data.frame(x)) {
    stop(sprintf(
      "`%s` must be a daily_load object. Build it with as_daily_load().", arg
    ), call. = FALSE)
  }
  problem <- daily_load_problem(x)
  if (!is.null(problem)) {
    stop(sprintf(
      "`%s` is no longer a valid daily_load: %s. This happens when the object is changed after it was built, for example by subsetting or reordering its rows. Rebuild it with as_daily_load().",
      arg, problem
    ), call. = FALSE)
  }
  invisible(x)
}

# Returns a description of the first violated invariant, or NULL.
daily_load_problem <- function(x) {
  # Columns and types --------------------------------------------------------
  columns <- list(
    athlete = list(ok = is.character, type = "character"),
    date = list(ok = function(v) inherits(v, "Date"), type = "Date"),
    load = list(ok = is.double, type = "numeric (double)"),
    status = list(ok = function(v) {
      is.factor(v) && identical(levels(v), day_states)
    }, type = "a factor with levels training, rest, missing"),
    n_sessions = list(ok = is.integer, type = "integer"),
    filled = list(ok = is.logical, type = "logical")
  )
  for (name in names(columns)) {
    if (!name %in% names(x)) {
      return(sprintf("column \"%s\" is missing", name))
    }
    if (!columns[[name]]$ok(x[[name]])) {
      return(sprintf("column \"%s\" must be %s", name, columns[[name]]$type))
    }
  }
  if ("performance" %in% names(x) && !is.double(x$performance)) {
    return("column \"performance\" must be numeric (double)")
  }

  # Attributes ---------------------------------------------------------------
  gaps <- attr(x, "gaps")
  if (is.null(gaps)) return("attribute \"gaps\" is missing")
  if (!is.character(gaps) || length(gaps) != 1L ||
      !gaps %in% c("rest", "missing")) {
    return("attribute \"gaps\" must be \"rest\" or \"missing\"")
  }
  load_name <- attr(x, "load_name")
  if (is.null(load_name)) return("attribute \"load_name\" is missing")
  if (!is.character(load_name) || length(load_name) != 1L ||
      is.na(load_name)) {
    return("attribute \"load_name\" must be a single string")
  }

  # Rows ---------------------------------------------------------------------
  n <- nrow(x)
  if (n == 0L) return("it has no rows")
  if (anyNA(x$athlete)) return("column \"athlete\" has NA")
  if (anyNA(x$date)) return("column \"date\" has NA")
  if (!identical(order(x$athlete, method = "radix"), seq_len(n))) {
    return("rows are not sorted by athlete")
  }
  same_athlete <- x$athlete[-1L] == x$athlete[-n]
  step <- as.numeric(x$date[-1L] - x$date[-n])
  bad <- which(same_athlete & step != 1)[1L]
  if (!is.na(bad)) {
    return(sprintf(
      "dates of athlete %s are not consecutive and sorted (%s is followed by %s)",
      x$athlete[bad], iso_date(x$date[bad]), iso_date(x$date[bad + 1L])
    ))
  }

  # Values -------------------------------------------------------------------
  bad <- which(is.nan(x$load) | is.infinite(x$load) | x$load < 0)[1L]
  if (!is.na(bad)) {
    return(sprintf("row %d has load %s; loads must be >= 0 or NA",
                   bad, format(x$load[bad])))
  }
  expected <- as.character(day_status(x$load))
  bad <- which(as.character(x$status) != expected | is.na(x$status))[1L]
  if (!is.na(bad)) {
    return(sprintf(
      "row %d has status \"%s\" but load %s (status \"%s\")",
      bad, as.character(x$status[bad]), format(x$load[bad]), expected[bad]
    ))
  }
  bad <- which(is.na(x$n_sessions) | x$n_sessions < 0L |
                 is.na(x$filled) | x$filled != (x$n_sessions == 0L))[1L]
  if (!is.na(bad)) {
    return(sprintf(
      "row %d has n_sessions %s and filled %s, which do not agree",
      bad, format(x$n_sessions[bad]), format(x$filled[bad])
    ))
  }
  NULL
}
