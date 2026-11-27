#' Convert between time constants and half-lives
#'
#' `half_life()` gives the number of days for a component to fall to half,
#' \eqn{\tau \ln 2}{tau * log(2)}, and `time_constant()` gives the time
#' constant \eqn{\tau}{tau} of a half-life (MODELS.md, Notation).
#'
#' Impulse-response functions take time constants, never half-lives; print
#' methods show the half-life next to each time constant (DECISIONS.md,
#' D-024).
#'
#' @param tau Time constants in days: a numeric vector of positive finite
#'   numbers.
#' @param half_life Half-lives in days: a numeric vector of positive finite
#'   numbers.
#'
#' @return A numeric vector of the same length.
#'
#' @seealso [simulate_banister()], [session_response()].
#'
#' @examples
#' half_life(c(45, 15))
#' time_constant(7)
#'
#' @export
half_life <- function(tau) {
  check_positive(tau, "tau")
  tau * log(2)
}

#' @rdname half_life
#' @export
time_constant <- function(half_life) {
  check_positive(half_life, "half_life")
  half_life / log(2)
}

check_positive <- function(x, arg) {
  if (!is.numeric(x) || length(x) == 0L || any(!is.finite(x)) ||
      any(x <= 0)) {
    stop(sprintf("`%s` must be a numeric vector of positive finite numbers.",
                 arg), call. = FALSE)
  }
}
