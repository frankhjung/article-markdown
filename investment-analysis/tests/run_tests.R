#!/usr/bin/env Rscript

# Non-interactive test runner for investment-analysis/tests/testthat/.
# Uses testthat when installed, or falls back to a minimal base-R testthat
# compatibility shim so the suite executes cleanly inside gnur:4.5.2.

#' @title Execute Stage 2 Test Suite via testthat or Base-R Shim
#' @description Runs `tests/testthat/test-model.R` and halts with exit status
#'   1 if any expectation fails or throws an unexpected error.
#' @return Invisibly returns the count of executed tests.
#' @examples
#' \dontrun{
#' run_stage2_tests()
#' }
run_stage2_tests <- function() {
  if (requireNamespace("testthat", quietly = TRUE)) {
    testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
    return(invisible(TRUE))
  }

  state <- new.env(parent = emptyenv())
  state$passed <- 0L
  state$failed <- 0L

  env <- new.env(parent = globalenv())

  env$test_that <- function(desc, code) {
    res <- tryCatch(
      {
        eval(substitute(code), envir = new.env(parent = env))
        NULL
      },
      error = function(e) e
    )
    if (is.null(res)) {
      state$passed <- state$passed + 1L
      cat(sprintf("[PASS] %s\n", desc))
    } else {
      state$failed <- state$failed + 1L
      cat(sprintf("[FAIL] %s -> %s\n", desc, conditionMessage(res)))
    }
  }

  env$expect_equal <- function(object, expected, tolerance = 1e-8) {
    cmp <- all.equal(object, expected, tolerance = tolerance, scale = 1)
    if (!isTRUE(cmp)) {
      stop(paste(cmp, collapse = "; "), call. = FALSE)
    }
    invisible(TRUE)
  }

  env$expect_true <- function(object) {
    if (!isTRUE(object)) {
      stop("Expected TRUE, got FALSE/non-scalar", call. = FALSE)
    }
    invisible(TRUE)
  }

  env$expect_error <- function(object, regexp = NULL) {
    err <- tryCatch(
      {
        force(object)
        NULL
      },
      error = function(e) e
    )
    if (is.null(err)) {
      stop("Expected an error, but expression succeeded", call. = FALSE)
    }
    if (!is.null(regexp) && !grepl(regexp, conditionMessage(err))) {
      stop(
        sprintf(
          "Error '%s' did not match '%s'",
          conditionMessage(err),
          regexp
        ),
        call. = FALSE
      )
    }
    invisible(TRUE)
  }

  test_files <- list.files(
    file.path("tests", "testthat"),
    pattern = "\\.[rR]$",
    full.names = TRUE
  )
  lapply(sort(test_files), function(tf) sys.source(tf, envir = env))

  cat(
    sprintf(
      "\nSummary: %d passed, %d failed\n",
      state$passed,
      state$failed
    )
  )
  if (state$failed > 0L) {
    stop(sprintf("%d test(s) failed", state$failed), call. = FALSE)
  }
  invisible(state$passed)
}

if (sys.nframe() == 0L) {
  run_stage2_tests()
}
