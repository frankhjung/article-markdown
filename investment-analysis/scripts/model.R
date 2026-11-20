#!/usr/bin/env Rscript

# Stage 2 Analytical Model: Pure Financial Transformations and Validations
#
# Sourced by article.Rmd at render time (locally and in CI container
# ghcr.io/frankhjung/gnur:4.5.2). Reads ONLY prepared UTF-8 CSVs in files/
# and files/historical-events.csv; never accesses .xlsx or files/raw-data/.
#
# Data Provenance (REQ-006; see files/raw-data/file-sources.md):
# - files/gold-prices.csv: World Bank Pink Sheet (Gold, USD/troy oz)
# - files/rba-aud-usd.csv: RBA Table F11 & F11 Historical (FXRUSD, A$1=USD)
# - files/rba-deposit-rates.csv: RBA Table F4 (FRDIRSAB10K, FRDIRBTD10K1Y)
# - files/rba-cash-rate.csv: RBA Table F1.1 Cash Rate Target (FIRMMCRT)
# - files/stw-prices.csv: Investing.com AU ASX:STW Monthly Close (AUD)
# - files/stw-distributions.csv: InvestSMART / SSGA ASX:STW Distributions
# - files/abs-cpi.csv: RBA / ABS Table G1 Consumer Price Index (GCPIAG)
# - files/historical-events.csv: Hand-authored 2006-2026 event catalogue

#' @title Assert Condition or Halt with Informative Error
#' @description Validates a scalar logical predicate and aborts via `stop()`
#'   with an explicit contextual error message if not `TRUE`.
#' @param condition Logical scalar expression expected to be `TRUE`.
#' @param message Character scalar error message emitted on failure.
#' @return Invisibly returns `TRUE` when `condition` is `TRUE`.
#' @examples
#' assert_true(2L + 2L == 4L, "Basic arithmetic invariant")
assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Read Prepared CSV File with Explicit Column Schema
#' @description Reads a Stage 1 prepared CSV from `files_dir` using `readr`
#'   without accessing raw workbooks or inferring guessed types silently.
#' @param files_dir Character scalar directory containing prepared CSV files.
#' @param filename Character scalar CSV filename inside `files_dir`.
#' @param col_spec Column specification created by `readr::cols()`.
#' @return A `tibble` containing parsed rows from `filename`.
#' @examples
#' \dontrun{
#' read_prepared_csv(
#'   "files",
#'   "abs-cpi.csv",
#'   readr::cols(
#'     date = readr::col_date("%Y-%m-%d"),
#'     cpi_index = readr::col_double()
#'   )
#' )
#' }
read_prepared_csv <- function(files_dir, filename, col_spec) {
  path <- file.path(files_dir, filename)
  assert_true(
    file.exists(path),
    sprintf("Missing prepared CSV input: %s", path)
  )
  readr::read_csv(
    path,
    col_types = col_spec,
    show_col_types = FALSE,
    progress = FALSE
  )
}

#' @title Load All Prepared Inputs and Historical Event Catalogue
#' @description Loads the seven Stage 1 prepared CSVs and hand-authored
#'   `historical-events.csv` from `files_dir` into a structured named list.
#' @param files_dir Character scalar path to `investment-analysis/files`.
#' @return Named list of eight `tibble` inputs for downstream modelling.
#' @examples
#' \dontrun{
#' inputs <- load_prepared_data("files")
#' names(inputs)
#' }
load_prepared_data <- function(files_dir = "files") {
  date_col <- readr::col_date(format = "%Y-%m-%d")
  num_col <- readr::col_double()
  chr_col <- readr::col_character()

  list(
    gold = read_prepared_csv(
      files_dir,
      "gold-prices.csv",
      readr::cols(date = date_col, gold_usd = num_col)
    ),
    fx = read_prepared_csv(
      files_dir,
      "rba-aud-usd.csv",
      readr::cols(date = date_col, aud_usd = num_col)
    ),
    stw_prices = read_prepared_csv(
      files_dir,
      "stw-prices.csv",
      readr::cols(date = date_col, stw_price_aud = num_col)
    ),
    stw_distributions = read_prepared_csv(
      files_dir,
      "stw-distributions.csv",
      readr::cols(
        ex_dividend_date = date_col,
        payment_date = date_col,
        cash_distribution_aud = num_col,
        franking_pct = num_col,
        gross_distribution_aud = num_col
      )
    ),
    deposit_rates = read_prepared_csv(
      files_dir,
      "rba-deposit-rates.csv",
      readr::cols(
        date = date_col,
        bonus_savings_rate_pct = num_col,
        term_deposit_1y_rate_pct = num_col
      )
    ),
    cpi = read_prepared_csv(
      files_dir,
      "abs-cpi.csv",
      readr::cols(date = date_col, cpi_index = num_col)
    ),
    cash_rate = read_prepared_csv(
      files_dir,
      "rba-cash-rate.csv",
      readr::cols(date = date_col, cash_rate_pct = num_col)
    ),
    historical_events = read_prepared_csv(
      files_dir,
      "historical-events.csv",
      readr::cols(
        event_id = chr_col,
        date = date_col,
        end_date = date_col,
        label = chr_col,
        short_label = chr_col,
        primary_asset = chr_col,
        impact_direction = chr_col,
        summary = chr_col,
        chart_priority = readr::col_integer()
      )
    )
  )
}

#' @title Compute Uninterpolated CPI Inflation Ratio Over Horizon
#' @description Computes the exact ratio `cpi_end / cpi_start` from ABS Table
#'   G1 quarterly observations without monthly interpolation.
#' @param cpi_df Data frame containing `date` (`Date`) and `cpi_index`.
#' @param start_date `Date` scalar baseline quarter (`"2006-06-01"`).
#' @param end_date `Date` scalar ending quarter (`"2026-06-01"`).
#' @return Named list with `start_index`, `end_index`, `ratio`, `cum_pct`, and
#'   `breakeven_aud`.
#' @examples
#' sample_cpi <- data.frame(
#'   date = as.Date(c("2006-06-01", "2026-06-01")),
#'   cpi_index = c(59.65, 102.31)
#' )
#' compute_cpi_ratio(sample_cpi)
compute_cpi_ratio <- function(
  cpi_df,
  start_date = as.Date("2006-06-01"),
  end_date = as.Date("2026-06-01")
) {
  start_idx <- which(cpi_df$date == start_date)
  end_idx <- which(cpi_df$date == end_date)
  assert_true(
    length(start_idx) == 1L && length(end_idx) == 1L,
    "CPI index missing baseline or ending quarter date"
  )
  start_val <- cpi_df$cpi_index[[start_idx]]
  end_val <- cpi_df$cpi_index[[end_idx]]
  assert_true(
    start_val > 0 && end_val > 0,
    "CPI index values must be strictly positive"
  )
  ratio <- end_val / start_val
  list(
    start_index = start_val,
    end_index = end_val,
    ratio = ratio,
    cum_pct = (ratio - 1) * 100,
    breakeven_aud = 1000 * ratio
  )
}

#' @title Filter `ASX:STW` Distributions Inside Analysis Entitlement Window
#' @description Retains distributions whose `ex_dividend_date` falls within the
#'   investment holding window (`start_date` through end of `end_date` month)
#'   and attaches each distribution's canonical `payment_month`.
#' @param dist_df Data frame with `ex_dividend_date`, `payment_date`, and
#'   payout fields.
#' @param start_date `Date` scalar entry date (`"2006-07-01"`).
#' @param end_date `Date` scalar exit month (`"2026-07-01"`).
#' @return Sorted `tibble` of eligible distributions with `payment_month`.
#' @examples
#' \dontrun{
#' elig <- filter_stw_distributions(inputs$stw_distributions)
#' nrow(elig)
#' }
filter_stw_distributions <- function(
  dist_df,
  start_date = as.Date("2006-07-01"),
  end_date = as.Date("2026-07-01")
) {
  window_end <- lubridate::ceiling_date(end_date, "month") - 1L
  keep <- dist_df$ex_dividend_date >= start_date &
    dist_df$ex_dividend_date <= window_end
  elig <- dist_df[keep, , drop = FALSE]
  elig <- elig[order(elig$payment_date, elig$ex_dividend_date), , drop = FALSE]
  elig$payment_month <- lubridate::floor_date(elig$payment_date, "month")
  tibble::as_tibble(elig)
}

#' @title Align Monthly Series and Distributions onto Canonical Date Grid
#' @description Joins Gold, AUD/USD FX, RBA deposit rates, RBA cash rate, STW
#'   prices, and eligible STW distributions onto 241 contiguous monthly dates.
#' @param inputs Named list returned by `load_prepared_data()`.
#' @param start_date `Date` scalar first month (`"2006-07-01"`).
#' @param end_date `Date` scalar final month (`"2026-07-01"`).
#' @return `tibble` of aligned monthly inputs and zero-padded STW payouts.
#' @examples
#' \dontrun{
#' aligned <- align_monthly_inputs(load_prepared_data("files"))
#' nrow(aligned)
#' }
align_monthly_inputs <- function(
  inputs,
  start_date = as.Date("2006-07-01"),
  end_date = as.Date("2026-07-01")
) {
  grid <- tibble::tibble(
    date = seq.Date(from = start_date, to = end_date, by = "month")
  )
  elig_dist <- filter_stw_distributions(
    inputs$stw_distributions,
    start_date,
    end_date
  )
  assert_true(
    all(elig_dist$payment_month %in% grid$date),
    "Eligible STW payment month falls outside analysis window"
  )

  monthly_dist <- if (nrow(elig_dist) == 0L) {
    tibble::tibble(
      date = as.Date(character()),
      stw_cash_dist_aud = numeric(),
      stw_gross_dist_aud = numeric(),
      stw_franking_pct = numeric()
    )
  } else {
    elig_dist |>
      split(elig_dist$payment_month) |>
      purrr::map(function(df) {
        tibble::tibble(
          date = df$payment_month[[1L]],
          stw_cash_dist_aud = sum(df$cash_distribution_aud),
          stw_gross_dist_aud = sum(df$gross_distribution_aud),
          stw_franking_pct = stats::weighted.mean(
            df$franking_pct,
            df$cash_distribution_aud
          )
        )
      }) |>
      dplyr::bind_rows()
  }

  aligned <- grid |>
    dplyr::left_join(inputs$gold, by = "date") |>
    dplyr::left_join(inputs$fx, by = "date") |>
    dplyr::left_join(inputs$deposit_rates, by = "date") |>
    dplyr::left_join(inputs$cash_rate, by = "date") |>
    dplyr::left_join(inputs$stw_prices, by = "date") |>
    dplyr::left_join(monthly_dist, by = "date")

  core_cols <- c(
    "gold_usd",
    "aud_usd",
    "bonus_savings_rate_pct",
    "term_deposit_1y_rate_pct",
    "cash_rate_pct",
    "stw_price_aud"
  )
  has_missing <- vapply(
    aligned[core_cols],
    anyNA,
    logical(1L)
  )
  assert_true(
    !any(has_missing),
    "Aligned monthly inputs contain missing values across core series"
  )

  aligned$gold_aud <- aligned$gold_usd / aligned$aud_usd
  aligned$stw_cash_dist_aud <- dplyr::coalesce(aligned$stw_cash_dist_aud, 0)
  aligned$stw_gross_dist_aud <- dplyr::coalesce(aligned$stw_gross_dist_aud, 0)
  aligned$stw_franking_pct <- dplyr::coalesce(aligned$stw_franking_pct, 0)
  aligned
}

#' @title Compute Indexed AUD Gold Spot and Net-of-MER ETF Series
#' @description Converts AUD gold prices into a cumulative wealth series from
#'   `initial_aud` and applies continuous annual ETF MER compounding factors.
#' @param gold_aud Numeric vector of spot gold prices in `AUD/troy oz`.
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @param mer_low Numeric scalar low-cost Gold ETF annual MER (`0.0015`).
#' @param mer_high Numeric scalar higher-cost Gold ETF annual MER (`0.0040`).
#' @return `tibble` with `gold_value_aud`, `gold_etf_015_value_aud`, and
#'   `gold_etf_040_value_aud`.
#' @examples
#' compute_gold_series(c(800, 1000, 1200))
compute_gold_series <- function(
  gold_aud,
  initial_aud = 1000,
  mer_low = 0.0015,
  mer_high = 0.0040
) {
  assert_true(
    length(gold_aud) >= 1L && all(gold_aud > 0),
    "AUD gold prices must be strictly positive"
  )
  t_idx <- seq_along(gold_aud) - 1L
  spot <- initial_aud * (gold_aud / gold_aud[[1L]])
  tibble::tibble(
    gold_value_aud = spot,
    gold_etf_015_value_aud = spot * ((1 - mer_low)^(t_idx / 12)),
    gold_etf_040_value_aud = spot * ((1 - mer_high)^(t_idx / 12))
  )
}

#' @title Compute July-Locked Annual Rollover Fixed Interest Trajectory
#' @description Models Fixed Interest by locking each July's published annual
#'   rate (`rates_pct`) for a 12-month term, accruing linear monthly interest
#'   during intermediate months, and compounding at maturity after optional tax.
#' @param dates `Date` vector of contiguous monthly observations (`1 + 12*k`).
#' @param rates_pct Numeric vector of annualised deposit rates (`%` p.a.).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @param tax_rate Numeric scalar marginal tax + Medicare levy rate in `[0, 1)`.
#' @return Numeric vector of portfolio values matching length of `dates`.
#' @examples
#' dts <- seq.Date(as.Date("2006-07-01"), as.Date("2007-07-01"), by = "month")
#' compute_annual_rollover(dts, rep(5, length(dts)))
compute_annual_rollover <- function(
  dates,
  rates_pct,
  initial_aud = 1000,
  tax_rate = 0
) {
  n_obs <- length(dates)
  assert_true(
    n_obs == length(rates_pct) && n_obs >= 13L && (n_obs - 1L) %% 12L == 0L,
    "Annual rollover requires 1 + 12*k contiguous monthly points"
  )
  n_terms <- (n_obs - 1L) %/% 12L
  july_idx <- seq.int(from = 1L, to = n_obs - 12L, by = 12L)
  lock_rates <- rates_pct[july_idx] / 100

  balances <- purrr::accumulate(
    lock_rates,
    function(bal, rate) bal * (1 + rate * (1 - tax_rate)),
    .init = initial_aud
  ) |>
    unlist(use.names = FALSE)

  month_offsets <- rep(seq.int(0L, 11L), times = n_terms)
  term_balances <- rep(balances[seq_len(n_terms)], each = 12L)
  term_rates <- rep(lock_rates, each = 12L)
  accrued <- term_balances * (1 + term_rates * (month_offsets / 12))

  c(accrued, balances[[n_terms + 1L]])
}

#' @title Compute Monthly-Compounded RBA Cash Rate Benchmark
#' @description Compounds monthly `FIRMMCRT / 12` rates across consecutive
#'   months without loops using `cumprod()`.
#' @param cash_rate_pct Numeric vector of RBA cash rates (`%` p.a.).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @param tax_rate Numeric scalar marginal tax + Medicare levy rate in `[0, 1)`.
#' @return Numeric vector of compounded values matching `cash_rate_pct`.
#' @examples
#' compute_cash_rate_series(c(6, 6, 6))
compute_cash_rate_series <- function(
  cash_rate_pct,
  initial_aud = 1000,
  tax_rate = 0
) {
  n_obs <- length(cash_rate_pct)
  assert_true(n_obs >= 1L, "Cash rate series cannot be empty")
  if (n_obs == 1L) {
    return(initial_aud)
  }
  monthly_factors <- 1 +
    (cash_rate_pct[seq_len(n_obs - 1L)] / 1200) * (1 - tax_rate)
  cumprod(c(initial_aud, monthly_factors))
}

#' @title Compute `ASX:STW` Price-Only Growth Index
#' @description Indexes `ASX:STW` closing unit prices to `initial_aud` without
#'   distribution reinvestment.
#' @param stw_price_aud Numeric vector of monthly `ASX:STW` prices (`AUD`).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @return Numeric vector of price-only portfolio values.
#' @examples
#' compute_stw_price_only(c(50, 55, 60))
compute_stw_price_only <- function(stw_price_aud, initial_aud = 1000) {
  assert_true(
    length(stw_price_aud) >= 1L && all(stw_price_aud > 0),
    "STW prices must be strictly positive"
  )
  initial_aud * (stw_price_aud / stw_price_aud[[1L]])
}

#' @title Compute `ASX:STW` Fractional Cash DRP Total Return
#' @description Tracks cumulative units and portfolio value when eligible cash
#'   distributions buy fractional `ASX:STW` units in each payment month.
#' @param stw_price_aud Numeric vector of aligned monthly STW prices (`AUD`).
#' @param cash_dist_aud Numeric vector of aligned monthly cash payouts (`AUD`).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @return `tibble` with `units` and `value_aud`.
#' @examples
#' compute_stw_fractional_drp(c(50, 52, 55), c(0, 1.5, 0))
compute_stw_fractional_drp <- function(
  stw_price_aud,
  cash_dist_aud,
  initial_aud = 1000
) {
  assert_true(
    length(stw_price_aud) == length(cash_dist_aud) &&
      all(stw_price_aud > 0) &&
      cash_dist_aud[[1L]] == 0,
    "Invalid STW price/distribution vectors for fractional DRP"
  )
  init_units <- initial_aud / stw_price_aud[[1L]]
  units <- init_units * cumprod(1 + cash_dist_aud / stw_price_aud)
  tibble::tibble(
    units = units,
    value_aud = units * stw_price_aud
  )
}

#' @title Compute `ASX:STW` Whole-Unit DRP with Cash Carry-Forward Ledger
#' @description Mirrors a practical ASX Dividend Reinvestment Plan by buying
#'   whole units (`floor(initial_aud / price_0)`) and carrying residual cash
#'   in a `0%`-interest ledger until cash buys whole units.
#' @param stw_price_aud Numeric vector of aligned monthly STW prices (`AUD`).
#' @param cash_dist_aud Numeric vector of aligned monthly cash payouts (`AUD`).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @return `tibble` with integer-valued `units`, `residual_cash`, and
#'   `value_aud`.
#' @examples
#' compute_stw_whole_unit_drp(c(49.19, 50.46, 51.09), c(0, 1.0, 2.5))
compute_stw_whole_unit_drp <- function(
  stw_price_aud,
  cash_dist_aud,
  initial_aud = 1000
) {
  assert_true(
    length(stw_price_aud) == length(cash_dist_aud) &&
      all(stw_price_aud > 0) &&
      cash_dist_aud[[1L]] == 0,
    "Invalid STW price/distribution vectors for whole-unit DRP"
  )
  init_units <- floor(initial_aud / stw_price_aud[[1L]])
  init_cash <- initial_aud - init_units * stw_price_aud[[1L]]
  init_state <- list(units = init_units, cash = init_cash)

  step_fn <- function(state, idx) {
    px <- stw_price_aud[[idx]]
    cash_in <- state$cash + state$units * cash_dist_aud[[idx]]
    bought <- if (cash_in >= px) floor(cash_in / px) else 0
    list(
      units = state$units + bought,
      cash = cash_in - bought * px
    )
  }

  states <- purrr::accumulate(
    seq_along(stw_price_aud),
    step_fn,
    .init = init_state
  )[-1L]

  units_vec <- vapply(states, function(s) s$units, numeric(1L))
  cash_vec <- vapply(states, function(s) s$cash, numeric(1L))
  tibble::tibble(
    units = units_vec,
    residual_cash = cash_vec,
    value_aud = units_vec * stw_price_aud + cash_vec
  )
}

#' @title Compute ATO Parcel-Level Capital Gains Tax at Liquidation
#' @description Evaluates net CGT payable upon selling all unit parcels at
#'   `exit_price`, offsetting capital losses against non-discounted short-term
#'   gains before discounted long-term gains held `> 12` months.
#' @param parcels_df Data frame with columns `acq_date`, `units`, `cost_base`.
#' @param exit_price Numeric scalar liquidation price per unit (`AUD`).
#' @param tax_rate Numeric scalar marginal tax + Medicare levy rate.
#' @param discount_cutoff `Date` scalar (`12` months prior to disposal date).
#' @return Numeric scalar CGT payable in `AUD`.
#' @examples
#' parcels <- tibble::tibble(
#'   acq_date = as.Date(c("2006-07-01", "2026-04-15")),
#'   units = c(10, 1),
#'   cost_base = c(500, 78)
#' )
#' compute_parcel_cgt(parcels, 80.22, 0.32)
compute_parcel_cgt <- function(
  parcels_df,
  exit_price,
  tax_rate,
  discount_cutoff = as.Date("2025-07-01")
) {
  gains <- parcels_df$units * exit_price - parcels_df$cost_base
  losses <- sum(abs(gains[gains < 0]))
  short_gains <- sum(gains[gains > 0 & parcels_df$acq_date >= discount_cutoff])
  long_gains <- sum(gains[gains > 0 & parcels_df$acq_date < discount_cutoff])

  short_net <- max(0, short_gains - losses)
  rem_loss <- max(0, losses - short_gains)
  long_net <- max(0, long_gains - rem_loss)
  taxable_gain <- short_net + long_net * 0.5
  taxable_gain * tax_rate
}

#' @title Compute `ASX:STW` After-Tax Wealth Under AMIT and Parcel CGT Rules
#' @description Attributes each distribution to its `ex_dividend_date` AMIT
#'   financial year, applies franking credit offsets and marginal tax,
#'   reinvests only net after-tax cash as dated parcels, and deducts
#'   parcel-level CGT on liquidation.
#' @param dates `Date` vector of aligned monthly observation dates.
#' @param stw_price_aud Numeric vector of aligned STW prices (`AUD`).
#' @param distributions_df Raw/prepared `stw-distributions` data frame.
#' @param tax_rate Numeric scalar marginal tax + Medicare levy rate.
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @param discount_cutoff `Date` scalar earliest date excluded from 50% CGT
#'   discount (`"2025-07-01"` for July 2026 disposal).
#' @return Named list with `net_nominal_aud`, `gross_proceeds_aud`,
#'   `cgt_tax_aud`, `total_units`, and `parcels`.
#' @examples
#' \dontrun{
#' compute_stw_after_tax(
#'   aligned$date,
#'   aligned$stw_price_aud,
#'   inputs$stw_distributions,
#'   0.32
#' )
#' }
compute_stw_after_tax <- function(
  dates,
  stw_price_aud,
  distributions_df,
  tax_rate,
  initial_aud = 1000,
  discount_cutoff = as.Date("2025-07-01")
) {
  elig <- filter_stw_distributions(
    distributions_df,
    start_date = dates[[1L]],
    end_date = dates[[length(dates)]]
  )
  price_idx <- match(elig$payment_month, dates)
  assert_true(
    !anyNA(price_idx),
    "STW distribution payment month missing from price timeline"
  )
  elig$pay_price <- stw_price_aud[price_idx]
  elig$amit_fy <- ifelse(
    lubridate::month(elig$ex_dividend_date) >= 7L,
    lubridate::year(elig$ex_dividend_date) + 1L,
    lubridate::year(elig$ex_dividend_date)
  )

  init_units <- initial_aud / stw_price_aud[[1L]]
  init_parcel <- tibble::tibble(
    acq_date = dates[[1L]],
    amit_fy = NA_integer_,
    units = init_units,
    cost_base = initial_aud
  )

  step_dist <- function(state, row_idx) {
    row <- elig[row_idx, , drop = FALSE]
    cash_dist <- state$units * row$cash_distribution_aud
    gross_dist <- state$units * row$gross_distribution_aud
    franking_credit <- gross_dist - cash_dist
    net_tax <- gross_dist * tax_rate - franking_credit
    net_reinvested <- cash_dist - net_tax
    new_units <- net_reinvested / row$pay_price

    new_parcel <- tibble::tibble(
      acq_date = row$payment_date,
      amit_fy = as.integer(row$amit_fy),
      units = new_units,
      cost_base = net_reinvested
    )
    list(
      units = state$units + new_units,
      parcels = dplyr::bind_rows(state$parcels, new_parcel)
    )
  }

  final_state <- purrr::reduce(
    seq_len(nrow(elig)),
    step_dist,
    .init = list(units = init_units, parcels = init_parcel)
  )

  exit_price <- stw_price_aud[[length(stw_price_aud)]]
  gross_proceeds <- final_state$units * exit_price
  cgt_tax <- compute_parcel_cgt(
    final_state$parcels,
    exit_price,
    tax_rate,
    discount_cutoff
  )
  list(
    net_nominal_aud = gross_proceeds - cgt_tax,
    gross_proceeds_aud = gross_proceeds,
    cgt_tax_aud = cgt_tax,
    total_units = final_state$units,
    parcels = final_state$parcels
  )
}

#' @title Compute Gold After-Tax Value Upon Disposal After >12 Months
#' @description Applies the Australian 50% CGT discount for a single parcel
#'   held continuously over the full 20-year window.
#' @param end_value_aud Numeric scalar gross ending portfolio value (`AUD`).
#' @param tax_rate Numeric scalar marginal tax + Medicare levy rate.
#' @param initial_aud Numeric scalar initial capital cost base (`1000`).
#' @return Numeric scalar net after-tax proceeds (`AUD`).
#' @examples
#' compute_gold_after_tax(6998.18, 0.32)
compute_gold_after_tax <- function(
  end_value_aud,
  tax_rate,
  initial_aud = 1000
) {
  gain <- max(0, end_value_aud - initial_aud)
  end_value_aud - gain * 0.5 * tax_rate
}

#' @title Compute Return and Underwater Drawdown Metrics for a Wealth Series
#' @description Computes monthly simple returns, cumulative return percentages,
#'   and peak-to-trough underwater drawdowns (`<= 0`).
#' @param dates `Date` vector aligned to `value_aud`.
#' @param value_aud Numeric vector of strictly positive portfolio values.
#' @param initial_aud Numeric scalar baseline capital (`1000`).
#' @return `tibble` with `date`, `value_aud`, `monthly_return`,
#'   `cum_return_pct`, and `drawdown_pct`.
#' @examples
#' compute_series_metrics(
#'   as.Date(c("2006-07-01", "2006-08-01", "2006-09-01")),
#'   c(1000, 1200, 900)
#' )
compute_series_metrics <- function(dates, value_aud, initial_aud = 1000) {
  n_obs <- length(value_aud)
  assert_true(
    n_obs == length(dates) && n_obs >= 2L && all(value_aud > 0),
    "Series metrics require >= 2 positive observations matching dates"
  )
  monthly_return <- c(
    NA_real_,
    value_aud[seq.int(2L, n_obs)] / value_aud[seq.int(1L, n_obs - 1L)] - 1
  )
  cum_return_pct <- (value_aud / initial_aud - 1) * 100
  drawdown_pct <- (value_aud / cummax(value_aud) - 1) * 100

  tibble::tibble(
    date = dates,
    value_aud = value_aud,
    monthly_return = monthly_return,
    cum_return_pct = cum_return_pct,
    drawdown_pct = drawdown_pct
  )
}

#' @title Summarise One Series Variant into Headline Risk and Tax Metrics
#' @description Aggregates a long-format series tibble into CAGR, annualised
#'   volatility, maximum drawdown, real CPI-adjusted value, and after-tax rows.
#' @param meta Named list describing `asset_class`, `series_variant`,
#'   `values`, `tax32`, and `tax39`.
#' @param dates `Date` vector covering the 20-year window.
#' @param cpi_ratio Numeric scalar CPI deflator ratio (`1.71517...`).
#' @param years Numeric scalar horizon length in years (`20`).
#' @param initial_aud Numeric scalar starting capital (`1000`).
#' @return Single-row `tibble` conforming to `summary_metrics` contract.
#' @examples
#' \dontrun{
#' summarise_variant_row(meta, dates, 1.71517)
#' }
summarise_variant_row <- function(
  meta,
  dates,
  cpi_ratio,
  years = 20,
  initial_aud = 1000
) {
  metrics <- compute_series_metrics(dates, meta$values, initial_aud)
  end_nom <- metrics$value_aud[[nrow(metrics)]]
  vol_pct <- stats::sd(metrics$monthly_return, na.rm = TRUE) * sqrt(12) * 100

  tibble::tibble(
    asset_class = meta$asset_class,
    series_variant = meta$series_variant,
    end_value_nominal_aud = end_nom,
    total_return_pct = (end_nom / initial_aud - 1) * 100,
    cagr_pct = ((end_nom / initial_aud)^(1 / years) - 1) * 100,
    annual_volatility_pct = vol_pct,
    max_drawdown_pct = min(metrics$drawdown_pct),
    end_value_real_aud = end_nom / cpi_ratio,
    after_tax_32_nominal_aud = meta$tax32,
    after_tax_32_real_aud = if (is.na(meta$tax32)) {
      NA_real_
    } else {
      meta$tax32 / cpi_ratio
    },
    after_tax_39_nominal_aud = meta$tax39,
    after_tax_39_real_aud = if (is.na(meta$tax39)) {
      NA_real_
    } else {
      meta$tax39 / cpi_ratio
    }
  )
}

#' @title Build All Stage 2 In-Memory Analytical Data Contracts
#' @description Reads prepared CSVs in `files_dir`, computes all nine monthly
#'   wealth trajectories (`gold_aud`, Gold ETF sensitivities, Fixed Interest
#'   models, `ASX:STW` DRP/Price-Only variants), after-tax ATO scenarios, and
#'   validates every `REQ-011` output structure.
#' @param files_dir Character scalar path to prepared CSV directory.
#' @return Named list containing `asset_performance_monthly`,
#'   `asset_performance_wide`, `historical_events`, `summary_metrics`, and
#'   supplementary audit objects (`cpi_summary`, `stw_whole_unit`, `stw_tax`).
#' @examples
#' \dontrun{
#' model <- build_model_outputs("files")
#' validate_model_outputs(model)
#' }
build_model_outputs <- function(files_dir = "files") {
  inputs <- load_prepared_data(files_dir)
  cpi_info <- compute_cpi_ratio(inputs$cpi)
  aligned <- align_monthly_inputs(inputs)
  dts <- aligned$date

  gold_tbl <- compute_gold_series(aligned$gold_aud)
  fi_bonus <- compute_annual_rollover(dts, aligned$bonus_savings_rate_pct)
  fi_td_1y <- compute_annual_rollover(dts, aligned$term_deposit_1y_rate_pct)
  fi_cash <- compute_cash_rate_series(aligned$cash_rate_pct)

  stw_fr <- compute_stw_fractional_drp(
    aligned$stw_price_aud,
    aligned$stw_cash_dist_aud
  )
  stw_wu <- compute_stw_whole_unit_drp(
    aligned$stw_price_aud,
    aligned$stw_cash_dist_aud
  )
  stw_px <- compute_stw_price_only(aligned$stw_price_aud)

  fi_bonus_32 <- compute_annual_rollover(
    dts, aligned$bonus_savings_rate_pct, tax_rate = 0.32
  )
  fi_bonus_39 <- compute_annual_rollover(
    dts, aligned$bonus_savings_rate_pct, tax_rate = 0.39
  )
  fi_td_32 <- compute_annual_rollover(
    dts, aligned$term_deposit_1y_rate_pct, tax_rate = 0.32
  )
  fi_td_39 <- compute_annual_rollover(
    dts, aligned$term_deposit_1y_rate_pct, tax_rate = 0.39
  )
  fi_cash_32 <- compute_cash_rate_series(aligned$cash_rate_pct, tax_rate = 0.32)
  fi_cash_39 <- compute_cash_rate_series(aligned$cash_rate_pct, tax_rate = 0.39)

  stw_tax_32 <- compute_stw_after_tax(
    dts, aligned$stw_price_aud, inputs$stw_distributions, 0.32
  )
  stw_tax_39 <- compute_stw_after_tax(
    dts, aligned$stw_price_aud, inputs$stw_distributions, 0.39
  )

  n_obs <- length(dts)
  specs <- list(
    list(
      asset_class = "Gold",
      series_variant = "gold_aud",
      values = gold_tbl$gold_value_aud,
      tax32 = compute_gold_after_tax(gold_tbl$gold_value_aud[[n_obs]], 0.32),
      tax39 = compute_gold_after_tax(gold_tbl$gold_value_aud[[n_obs]], 0.39)
    ),
    list(
      asset_class = "Gold",
      series_variant = "gold_etf_015",
      values = gold_tbl$gold_etf_015_value_aud,
      tax32 = compute_gold_after_tax(
        gold_tbl$gold_etf_015_value_aud[[n_obs]], 0.32
      ),
      tax39 = compute_gold_after_tax(
        gold_tbl$gold_etf_015_value_aud[[n_obs]], 0.39
      )
    ),
    list(
      asset_class = "Gold",
      series_variant = "gold_etf_040",
      values = gold_tbl$gold_etf_040_value_aud,
      tax32 = compute_gold_after_tax(
        gold_tbl$gold_etf_040_value_aud[[n_obs]], 0.32
      ),
      tax39 = compute_gold_after_tax(
        gold_tbl$gold_etf_040_value_aud[[n_obs]], 0.39
      )
    ),
    list(
      asset_class = "Fixed Interest",
      series_variant = "fixed_interest_bonus",
      values = fi_bonus,
      tax32 = fi_bonus_32[[n_obs]],
      tax39 = fi_bonus_39[[n_obs]]
    ),
    list(
      asset_class = "Fixed Interest",
      series_variant = "fixed_interest_td_1y",
      values = fi_td_1y,
      tax32 = fi_td_32[[n_obs]],
      tax39 = fi_td_39[[n_obs]]
    ),
    list(
      asset_class = "Fixed Interest",
      series_variant = "fixed_interest_cash",
      values = fi_cash,
      tax32 = fi_cash_32[[n_obs]],
      tax39 = fi_cash_39[[n_obs]]
    ),
    list(
      asset_class = "Australian Equities",
      series_variant = "stw_total_return",
      values = stw_fr$value_aud,
      tax32 = stw_tax_32$net_nominal_aud,
      tax39 = stw_tax_39$net_nominal_aud
    ),
    list(
      asset_class = "Australian Equities",
      series_variant = "stw_total_return_whole_unit",
      values = stw_wu$value_aud,
      tax32 = NA_real_,
      tax39 = NA_real_
    ),
    list(
      asset_class = "Australian Equities",
      series_variant = "stw_price_only",
      values = stw_px,
      tax32 = NA_real_,
      tax39 = NA_real_
    )
  )

  monthly_long <- specs |>
    purrr::map(function(sp) {
      m <- compute_series_metrics(dts, sp$values)
      tibble::tibble(
        date = m$date,
        asset_class = sp$asset_class,
        series_variant = sp$series_variant,
        value_aud = m$value_aud,
        monthly_return = m$monthly_return,
        cum_return_pct = m$cum_return_pct,
        drawdown_pct = m$drawdown_pct
      )
    }) |>
    dplyr::bind_rows()

  summary_metrics <- specs |>
    purrr::map(function(sp) summarise_variant_row(sp, dts, cpi_info$ratio)) |>
    dplyr::bind_rows()

  wide_audit <- tibble::tibble(
    date = dts,
    gold_usd = aligned$gold_usd,
    aud_usd = aligned$aud_usd,
    gold_aud = aligned$gold_aud,
    bonus_savings_rate_pct = aligned$bonus_savings_rate_pct,
    term_deposit_1y_rate_pct = aligned$term_deposit_1y_rate_pct,
    cash_rate_pct = aligned$cash_rate_pct,
    stw_price_aud = aligned$stw_price_aud,
    stw_cash_dist_aud = aligned$stw_cash_dist_aud,
    stw_franking_pct = aligned$stw_franking_pct,
    gold_value_aud = gold_tbl$gold_value_aud,
    gold_etf_015_value_aud = gold_tbl$gold_etf_015_value_aud,
    gold_etf_040_value_aud = gold_tbl$gold_etf_040_value_aud,
    fixed_interest_value_aud = fi_bonus,
    td_1y_value_aud = fi_td_1y,
    cash_value_aud = fi_cash,
    stw_tr_value_aud = stw_fr$value_aud,
    stw_price_value_aud = stw_px
  )

  list(
    asset_performance_monthly = monthly_long,
    asset_performance_wide = wide_audit,
    historical_events = inputs$historical_events,
    summary_metrics = summary_metrics,
    cpi_summary = cpi_info,
    stw_whole_unit = list(
      end_units = stw_wu$units[[n_obs]],
      residual_cash_aud = stw_wu$residual_cash[[n_obs]],
      end_value_aud = stw_wu$value_aud[[n_obs]],
      fractional_end_units = stw_fr$units[[n_obs]],
      fractional_end_aud = stw_fr$value_aud[[n_obs]],
      gap_vs_fractional_aud = stw_fr$value_aud[[n_obs]] -
        stw_wu$value_aud[[n_obs]]
    ),
    stw_tax = list(
      tax_32 = stw_tax_32,
      tax_39 = stw_tax_39
    )
  )
}

#' @title Validate All REQ-012 Model Invariants and Data Contracts
#' @description Enforces structural schemas, 241-month timeline coverage, zero
#'   nulls, positive prices/FX, initial `1000.00` equality, ETF MER ordering,
#'   and STW Total Return dominance before allowing `article.Rmd` to chart.
#' @param model Named list returned by `build_model_outputs()`.
#' @return Invisibly returns `TRUE` when all invariants pass; otherwise aborts.
#' @examples
#' \dontrun{
#' model <- build_model_outputs("files")
#' validate_model_outputs(model)
#' }
validate_model_outputs <- function(model) {
  req_top <- c(
    "asset_performance_monthly",
    "asset_performance_wide",
    "historical_events",
    "summary_metrics"
  )
  assert_true(
    all(req_top %in% names(model)),
    "Model output list is missing required REQ-011 elements"
  )

  monthly <- model$asset_performance_monthly
  wide <- model$asset_performance_wide
  events <- model$historical_events
  summary_df <- model$summary_metrics

  exp_monthly_cols <- c(
    "date", "asset_class", "series_variant",
    "value_aud", "monthly_return", "cum_return_pct", "drawdown_pct"
  )
  exp_wide_cols <- c(
    "date", "gold_usd", "aud_usd", "gold_aud",
    "bonus_savings_rate_pct", "term_deposit_1y_rate_pct", "cash_rate_pct",
    "stw_price_aud", "stw_cash_dist_aud", "stw_franking_pct",
    "gold_value_aud", "gold_etf_015_value_aud", "gold_etf_040_value_aud",
    "fixed_interest_value_aud", "td_1y_value_aud", "cash_value_aud",
    "stw_tr_value_aud", "stw_price_value_aud"
  )
  exp_summary_cols <- c(
    "asset_class", "series_variant", "end_value_nominal_aud",
    "total_return_pct", "cagr_pct", "annual_volatility_pct",
    "max_drawdown_pct", "end_value_real_aud", "after_tax_32_nominal_aud",
    "after_tax_32_real_aud", "after_tax_39_nominal_aud",
    "after_tax_39_real_aud"
  )
  exp_variants <- c(
    "gold_aud", "gold_etf_015", "gold_etf_040",
    "fixed_interest_bonus", "fixed_interest_td_1y", "fixed_interest_cash",
    "stw_total_return", "stw_total_return_whole_unit", "stw_price_only"
  )

  assert_true(
    identical(names(monthly), exp_monthly_cols),
    "asset_performance_monthly schema mismatch"
  )
  assert_true(
    identical(names(wide), exp_wide_cols) && nrow(wide) == 241L,
    "asset_performance_wide schema or 241-row count mismatch"
  )
  assert_true(
    identical(names(summary_df), exp_summary_cols) &&
      nrow(summary_df) == length(exp_variants),
    "summary_metrics schema or variant count mismatch"
  )
  assert_true(
    nrow(events) >= 7L && !anyNA(events$chart_priority),
    "historical_events failed minimum row or non-null priority check"
  )
  assert_true(
    !anyNA(monthly$value_aud) &&
      !anyNA(monthly$cum_return_pct) &&
      !anyNA(monthly$drawdown_pct),
    "Missing values detected in monthly value, return, or drawdown"
  )
  assert_true(
    all(monthly$drawdown_pct <= 1e-12),
    "Drawdown values must never exceed zero"
  )
  assert_true(
    all(wide$gold_usd > 0) &&
      all(wide$aud_usd > 0) &&
      all(wide$gold_aud > 0) &&
      all(wide$stw_price_aud > 0) &&
      all(monthly$value_aud > 0),
    "Non-positive price, FX, or portfolio value detected"
  )

  expected_dates <- seq.Date(
    from = as.Date("2006-07-01"),
    to = as.Date("2026-07-01"),
    by = "month"
  )
  assert_true(
    identical(wide$date, expected_dates),
    "Wide table dates deviate from 2006-07-01..2026-07-01"
  )

  split_variants <- split(monthly, monthly$series_variant)
  assert_true(
    setequal(names(split_variants), exp_variants),
    "Missing or unexpected series_variant in asset_performance_monthly"
  )

  lapply(exp_variants, function(var_name) {
    sub_df <- split_variants[[var_name]]
    assert_true(
      nrow(sub_df) == 241L && identical(sub_df$date, expected_dates),
      sprintf("Series '%s' failed 241-month ascending date check", var_name)
    )
    assert_true(
      abs(sub_df$value_aud[[1L]] - 1000) <= 1e-9,
      sprintf("Series '%s' failed AUD 1,000.00 initial value check", var_name)
    )
  })

  assert_true(
    all(wide$gold_value_aud >= wide$gold_etf_015_value_aud - 1e-9) &&
      all(wide$gold_etf_015_value_aud >= wide$gold_etf_040_value_aud - 1e-9),
    "Gold ETF MER ordering invariant violated"
  )
  assert_true(
    all(wide$stw_tr_value_aud >= wide$stw_price_value_aud - 1e-9),
    "STW Total Return must always equal or exceed Price-Only"
  )
  invisible(TRUE)
}
