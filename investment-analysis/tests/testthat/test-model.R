# Unit and Integration Tests for Stage 2 Model (scripts/model.R)

source(file.path("scripts", "model.R"))

test_that("compute_cpi_ratio calculates exact uninterpolated ratio", {
  cpi_df <- data.frame(
    date = as.Date(c("2006-06-01", "2016-06-01", "2026-06-01")),
    cpi_index = c(50.0, 75.0, 100.0)
  )
  res <- compute_cpi_ratio(cpi_df)
  expect_equal(res$ratio, 2.0, tolerance = 1e-12)
  expect_equal(res$cum_pct, 100.0, tolerance = 1e-12)
  expect_equal(res$breakeven_aud, 2000.0, tolerance = 1e-12)
  expect_error(
    compute_cpi_ratio(cpi_df[c(1L, 2L), ]),
    "missing baseline or ending"
  )
})

test_that("compute_gold_series scales spot AUD and applies ETF MER drag", {
  res <- compute_gold_series(
    c(800, 1000, 1200),
    mer_low = 0.0015,
    mer_high = 0.0040
  )
  expect_equal(res$gold_value_aud, c(1000, 1250, 1500), tolerance = 1e-9)
  expect_equal(res$gold_etf_015_value_aud[[1L]], 1000, tolerance = 1e-9)
  expect_true(all(res$gold_value_aud >= res$gold_etf_015_value_aud))
  expect_true(all(res$gold_etf_015_value_aud >= res$gold_etf_040_value_aud))
  expect_error(compute_gold_series(c(800, 0)), "strictly positive")
})

test_that("compute_annual_rollover locks July rates and deducts tax at term", {
  dts <- seq.Date(as.Date("2006-07-01"), as.Date("2008-07-01"), by = "month")
  rates <- c(rep(4.0, 12L), rep(5.0, 12L), 6.0)
  gross <- compute_annual_rollover(dts, rates, initial_aud = 1000, tax_rate = 0)
  expect_equal(gross[[1L]], 1000, tolerance = 1e-9)
  expect_equal(gross[[7L]], 1020, tolerance = 1e-9)
  expect_equal(gross[[13L]], 1040, tolerance = 1e-9)
  expect_equal(gross[[25L]], 1040 * 1.05, tolerance = 1e-9)

  net30 <- compute_annual_rollover(
    dts,
    rates,
    initial_aud = 1000,
    tax_rate = 0.30
  )
  expected_net <- 1000 * (1 + 0.04 * 0.70) * (1 + 0.05 * 0.70)
  expect_equal(net30[[25L]], expected_net, tolerance = 1e-9)
})

test_that("compute_cash_rate_series compounds monthly rates cleanly", {
  res <- compute_cash_rate_series(c(12, 6, 3), initial_aud = 1000)
  expect_equal(res, c(1000, 1010, 1010 * 1.005), tolerance = 1e-9)
})

test_that("STW price-only, fractional DRP, and whole-unit DRP reconcile", {
  px <- c(50, 50, 60)
  dist <- c(0, 2.5, 0)
  p_only <- compute_stw_price_only(px)
  expect_equal(p_only, c(1000, 1000, 1200), tolerance = 1e-9)

  frac <- compute_stw_fractional_drp(px, dist)
  expect_equal(frac$units, c(20, 21, 21), tolerance = 1e-9)
  expect_equal(frac$value_aud, c(1000, 1050, 1260), tolerance = 1e-9)

  wu <- compute_stw_whole_unit_drp(c(49, 50, 60), c(0, 2.5, 1.0))
  # Initial: floor(1000/49) = 20 units (980), cash = 20.
  # Month 2: cash = 20 + 20*2.5 = 70 >= 50 -> buy 1 unit, units=21, cash=20.
  # Month 3: cash = 20 + 21*1.0 = 41 < 60 -> units=21, cash=41, val=1301.
  expect_equal(wu$units, c(20, 21, 21), tolerance = 1e-9)
  expect_equal(wu$residual_cash, c(20, 20, 41), tolerance = 1e-9)
  expect_equal(wu$value_aud[[3L]], 21 * 60 + 41, tolerance = 1e-9)
})

test_that("compute_parcel_cgt nets losses against short gains first", {
  parcels <- tibble::tibble(
    acq_date = as.Date(c("2010-01-01", "2026-01-01", "2026-04-01")),
    units = c(10, 10, 10),
    cost_base = c(400, 700, 900)
  )
  # At exit price 80: gains = +400 (long), +100 (short), -100 (loss).
  # Loss of 100 offsets short_gain 100 -> short_net = 0, long_net = 400.
  # Taxable = 400 * 0.5 = 200 -> CGT at 32% = 64.
  cgt <- compute_parcel_cgt(parcels, exit_price = 80, tax_rate = 0.32)
  expect_equal(cgt, 64, tolerance = 1e-9)
})

test_that("compute_stw_after_tax handles franking refunds and short parcels", {
  dts <- as.Date(c("2006-07-01", "2025-07-01", "2026-07-01"))
  px <- c(50, 75, 80)
  dists <- tibble::tibble(
    ex_dividend_date = as.Date(c("2025-06-29", "2026-06-29")),
    payment_date = as.Date(c("2025-07-11", "2026-07-13")),
    cash_distribution_aud = c(0.70, 0.70),
    franking_pct = c(1.0, 1.0),
    gross_distribution_aud = c(1.00, 1.00)
  )
  # At 19% tax, 1.00 grossed-up dividend incurs 0.19 tax vs 0.30 franking
  # credit, yielding a 0.11 refund so net reinvested > 0.70 cash.
  res19 <- compute_stw_after_tax(dts, px, dists, tax_rate = 0.19)
  expect_true(res19$parcels$cost_base[[2L]] > 20 * 0.70)
  expect_equal(res19$parcels$amit_fy, c(NA_integer_, 2025L, 2026L))
})

test_that("compute_gold_after_tax and compute_series_metrics match formulas", {
  expect_equal(compute_gold_after_tax(3000, 0.32), 3000 - 2000 * 0.5 * 0.32)
  expect_equal(compute_gold_after_tax(900, 0.32), 900)
  m <- compute_series_metrics(
    as.Date(c("2006-07-01", "2006-08-01", "2006-09-01")),
    c(1000, 1200, 900)
  )
  expect_true(is.na(m$monthly_return[[1L]]))
  expect_equal(m$monthly_return[c(2L, 3L)], c(0.20, -0.25), tolerance = 1e-9)
  expect_equal(m$drawdown_pct, c(0, 0, -25), tolerance = 1e-9)
})

test_that("validate_model_outputs fails immediately when invariants break", {
  model <- build_model_outputs("files")
  expect_true(validate_model_outputs(model))

  broken <- model
  broken$asset_performance_monthly$value_aud[[1L]] <- 999
  expect_error(validate_model_outputs(broken), "initial value check")
})

test_that("Full 2006-2026 model checks all REQ-010 and REQ-017 values", {
  model <- build_model_outputs("files")
  expect_true(validate_model_outputs(model))
  expect_equal(model$cpi_summary$ratio, 1.71517, tolerance = 1e-5)

  sm <- model$summary_metrics
  row_val <- function(variant, col) {
    sm[[col]][[which(sm$series_variant == variant)]]
  }

  expect_equal(
    row_val("gold_aud", "end_value_nominal_aud"),
    6998.18,
    tolerance = 0.01
  )
  expect_equal(
    row_val("gold_etf_015", "end_value_nominal_aud"),
    6791.20,
    tolerance = 0.01
  )
  expect_equal(
    row_val("gold_etf_040", "end_value_nominal_aud"),
    6459.10,
    tolerance = 0.01
  )
  expect_equal(
    row_val("fixed_interest_bonus", "end_value_nominal_aud"),
    1909.03,
    tolerance = 0.01
  )
  expect_equal(
    row_val("fixed_interest_td_1y", "end_value_nominal_aud"),
    2032.98,
    tolerance = 0.01
  )
  expect_equal(
    row_val("fixed_interest_cash", "end_value_nominal_aud"),
    1841.28,
    tolerance = 0.01
  )
  expect_equal(
    row_val("stw_total_return", "end_value_nominal_aud"),
    3899.71,
    tolerance = 0.01
  )
  expect_equal(
    row_val("stw_total_return_whole_unit", "end_value_nominal_aud"),
    3848.45,
    tolerance = 0.01
  )
  expect_equal(
    row_val("stw_price_only", "end_value_nominal_aud"),
    1630.82,
    tolerance = 0.01
  )

  expect_equal(
    row_val("gold_aud", "after_tax_32_nominal_aud"),
    6038.47,
    tolerance = 0.01
  )
  expect_equal(
    row_val("gold_aud", "after_tax_39_nominal_aud"),
    5828.54,
    tolerance = 0.01
  )
  expect_equal(
    row_val("fixed_interest_bonus", "after_tax_32_nominal_aud"),
    1556.50,
    tolerance = 0.01
  )
  expect_equal(
    row_val("fixed_interest_td_1y", "after_tax_32_nominal_aud"),
    1625.75,
    tolerance = 0.01
  )
  expect_equal(
    row_val("stw_total_return", "after_tax_32_nominal_aud"),
    3314.54,
    tolerance = 0.01
  )
  expect_equal(
    row_val("stw_total_return", "after_tax_39_nominal_aud"),
    3024.39,
    tolerance = 0.01
  )
})
