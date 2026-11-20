#!/usr/bin/env Rscript

# Stage 1 Data Preparation: Extract and Normalise Raw Inputs to Prepared CSVs
#
# Usage:
#   cd investment-analysis && Rscript scripts/convert_xlsx.R
#
# Reads permanent read-only inputs in files/raw-data/ and writes (overwriting
# prior extracts) clean UTF-8 prepared CSVs into files/, then verifies all
# REQ-008 invariants before exiting. Never modifies files/raw-data/.
#
# Data Provenance (REQ-006; retrieved 2026-11-19 / 2026-11-20):
# - CMO-Historical-Data-Monthly.xlsx: World Bank Pink Sheet ("Monthly Prices",
#   Gold, USD/troy oz; https://www.worldbank.org/en/research/commodity-markets)
# - rba-exchange-rates-1969-2009.xlsx: RBA Table F11 Historical (FXRUSD;
#   https://www.rba.gov.au/statistics/historical-data.html)
# - f11-data.csv: RBA Table F11 Exchange Rates (FXRUSD;
#   https://www.rba.gov.au/statistics/tables/csv/f11-data.csv)
# - f4-data.csv: RBA Table F4 Retail Deposit Rates (FRDIRSAB10K, FRDIRBTD10K1Y;
#   https://www.rba.gov.au/statistics/tables/csv/f4-data.csv)
# - f1.1-data.csv: RBA Table F1.1 Cash Rate Target (FIRMMCRT;
#   https://www.rba.gov.au/statistics/tables/csv/f1.1-data.csv)
# - g1-data.csv: RBA / ABS Table G1 CPI (GCPIAG, Sept 2025 = 100;
#   https://www.rba.gov.au/statistics/tables/csv/g1-data.csv)
# - stw-monthly-2006-2026.xlsx: Investing.com AU ASX:STW Monthly Close
#   (https://au.investing.com/etfs/spdr-s-p-asx-200-historical-data)
# - stw-dividends.csv: InvestSMART / SSGA ASX:STW Distribution Schedule
#   (see files/raw-data/file-sources.md for full canonical URLs & SHA-256)

#' @title Assert Condition or Halt with Informative Error
#' @description Validates a single scalar logical predicate and aborts via
#'   `stop()` with a clear contextual error message if false.
#' @param condition Logical scalar expression expected to be `TRUE`.
#' @param message Character scalar error message emitted on failure.
#' @return Invisibly returns `TRUE` when assertion passes.
#' @examples
#' assert_true(2L + 2L == 4L, "Basic arithmetic check")
assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

#' @title Convert Excel Column Letters to 1-Based Integer Indices
#' @description Maps uppercase Excel column codes (`"A"`, `"BR"`) to 1-based
#'   integer indices without loops using unique lookup memoisation.
#' @param letters_vec Character vector of Excel column letter prefixes.
#' @return Integer vector of corresponding 1-based column indices.
#' @examples
#' col_letters_to_index(c("A", "Z", "AA", "BR"))
col_letters_to_index <- function(letters_vec) {
  uniq_letters <- unique(letters_vec)
  uniq_idx <- vapply(
    strsplit(uniq_letters, "", fixed = TRUE),
    function(chars) {
      Reduce(
        function(acc, ch) acc * 26L + match(ch, LETTERS),
        chars,
        0L
      )
    },
    integer(1L)
  )
  uniq_idx[match(letters_vec, uniq_letters)]
}

#' @title Locate Worksheet XML Path Inside Unzipped OOXML Archive
#' @description Inspects `xl/workbook.xml` and `xl/_rels/workbook.xml.rels` to
#'   resolve a worksheet name to its archive-relative XML file path.
#' @param tmp_dir Character scalar directory containing unzipped `.xlsx` files.
#' @param sheet_name Character scalar worksheet tab name.
#' @return Character scalar file path to the worksheet XML file.
#' @examples
#' \dontrun{
#' resolve_sheet_xml_path("/tmp/unzipped_wb", "Monthly Prices")
#' }
resolve_sheet_xml_path <- function(tmp_dir, sheet_name) {
  wb_doc <- file.path(tmp_dir, "xl", "workbook.xml") |>
    xml2::read_xml() |>
    xml2::xml_ns_strip()
  sheet_nodes <- xml2::xml_find_all(wb_doc, "//sheets/sheet")
  sheet_names <- xml2::xml_attr(sheet_nodes, "name")
  sheet_rids <- xml2::xml_attr(sheet_nodes, "id")

  hit <- which(sheet_names == sheet_name)
  assert_true(
    length(hit) == 1L,
    sprintf("Worksheet '%s' not found in workbook.xml", sheet_name)
  )
  target_rid <- sheet_rids[[hit]]

  rels_doc <- file.path(tmp_dir, "xl", "_rels", "workbook.xml.rels") |>
    xml2::read_xml() |>
    xml2::xml_ns_strip()
  rel_nodes <- xml2::xml_find_all(rels_doc, "//Relationship")
  rel_ids <- xml2::xml_attr(rel_nodes, "Id")
  rel_targets <- xml2::xml_attr(rel_nodes, "Target")

  rel_hit <- which(rel_ids == target_rid)
  assert_true(
    length(rel_hit) == 1L,
    sprintf("Relationship '%s' missing for sheet '%s'", target_rid, sheet_name)
  )

  clean_target <- sub("^/+", "", rel_targets[[rel_hit]])
  rel_path <- if (startsWith(clean_target, "xl/")) {
    clean_target
  } else {
    file.path("xl", clean_target)
  }
  full_path <- file.path(tmp_dir, rel_path)
  assert_true(
    file.exists(full_path),
    sprintf("Resolved sheet XML missing at %s", full_path)
  )
  full_path
}

#' @title Read OOXML Shared String Table
#' @description Reads `xl/sharedStrings.xml` from an unzipped `.xlsx` directory
#'   and concatenates plain and rich-text runs into a character vector.
#' @param tmp_dir Character scalar directory containing unzipped `.xlsx` files.
#' @return Character vector indexed for 0-based Excel shared-string lookups.
#' @examples
#' \dontrun{
#' read_shared_strings("/tmp/unzipped_wb")
#' }
read_shared_strings <- function(tmp_dir) {
  ss_path <- file.path(tmp_dir, "xl", "sharedStrings.xml")
  if (!file.exists(ss_path)) {
    return(character(0L))
  }
  ss_doc <- xml2::read_xml(ss_path) |>
    xml2::xml_ns_strip()
  si_nodes <- xml2::xml_find_all(ss_doc, "//si")
  vapply(
    si_nodes,
    function(node) {
      t_nodes <- xml2::xml_find_all(node, "./t | ./r/t")
      paste0(xml2::xml_text(t_nodes), collapse = "")
    },
    character(1L)
  )
}

#' @title Decode Vector of OOXML Cell Nodes
#' @description Extracts scalar string values from vectorised XML `<c>` cell
#'   nodes handling shared strings, errors, inline strings, and numerics.
#' @param cells `xml_nodeset` of `<c>` worksheet cell elements.
#' @param shared_strings Character vector from `read_shared_strings()`.
#' @return Character vector of decoded cell values (`NA_character_` if blank).
#' @examples
#' \dontrun{
#' decode_xlsx_cells(cell_nodes, shared_strings)
#' }
decode_xlsx_cells <- function(cells, shared_strings) {
  types <- xml2::xml_attr(cells, "t")
  val_texts <- xml2::xml_text(xml2::xml_find_first(cells, "./v"))

  out <- val_texts
  out[!is.na(out) & !nzchar(out)] <- NA_character_

  is_shared <- !is.na(types) & types == "s"
  if (any(is_shared)) {
    ss_idx <- as.integer(val_texts[is_shared]) + 1L
    out[is_shared] <- shared_strings[ss_idx]
  }

  is_err <- !is.na(types) & types == "e"
  if (any(is_err)) {
    out[is_err] <- NA_character_
  }

  is_inline <- !is.na(types) & types == "inlineStr"
  if (any(is_inline)) {
    out[is_inline] <- vapply(
      cells[is_inline],
      function(cell) {
        txt <- xml2::xml_find_all(cell, "./is//t") |>
          xml2::xml_text()
        paste0(txt, collapse = "")
      },
      character(1L)
    )
  }
  out
}

#' @title Read Worksheet Into Dense Character Matrix via Base R and xml2
#' @description Unzips an `.xlsx` workbook into a temporary directory and loads
#'   a target sheet cleanly without requiring compiled Excel dependencies.
#' @param xlsx_path Character scalar path to `.xlsx` workbook.
#' @param sheet_name Character scalar worksheet tab name.
#' @return Character matrix representing all populated cells (`NA` when empty).
#' @examples
#' \dontrun{
#' read_xlsx_sheet(
#'   "files/raw-data/CMO-Historical-Data-Monthly.xlsx",
#'   "Monthly Prices"
#' )
#' }
read_xlsx_sheet <- function(xlsx_path, sheet_name) {
  assert_true(
    file.exists(xlsx_path),
    sprintf("Missing XLSX input file: %s", xlsx_path)
  )
  tmp_dir <- tempfile("xlsx_extract_")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(xlsx_path, exdir = tmp_dir)
  sheet_xml <- resolve_sheet_xml_path(tmp_dir, sheet_name)
  shared_strings <- read_shared_strings(tmp_dir)

  sheet_doc <- xml2::read_xml(sheet_xml) |>
    xml2::xml_ns_strip()
  cells <- xml2::xml_find_all(sheet_doc, "//sheetData/row/c")
  refs <- xml2::xml_attr(cells, "r")
  assert_true(
    length(refs) > 0L && !anyNA(refs),
    sprintf(
      "Worksheet '%s' in %s contains missing cell refs",
      sheet_name,
      xlsx_path
    )
  )

  col_idx <- col_letters_to_index(sub("[0-9]+$", "", refs))
  row_idx <- as.integer(sub("^[A-Z]+", "", refs))
  vals <- decode_xlsx_cells(cells, shared_strings)

  mat <- matrix(NA_character_, nrow = max(row_idx), ncol = max(col_idx))
  mat[cbind(row_idx, col_idx)] <- vals
  mat
}

#' @title Read Statistical CSV Published by the RBA
#' @description Reads an RBA statistical CSV skipping 10 metadata rows so row 11
#'   (`Series ID`) becomes column headers while handling UTF-8 BOM safely.
#' @param csv_path Character scalar path to an RBA CSV file.
#' @return Data frame with character columns named by RBA `Series ID`.
#' @examples
#' \dontrun{
#' read_rba_csv("files/raw-data/f4-data.csv")
#' }
read_rba_csv <- function(csv_path) {
  assert_true(
    file.exists(csv_path),
    sprintf("Missing CSV input file: %s", csv_path)
  )
  utils::read.csv(
    csv_path,
    skip = 10L,
    header = TRUE,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    colClasses = "character",
    fill = TRUE,
    fileEncoding = "UTF-8-BOM"
  )
}

#' @title Locate Unique Column Index by Header Name
#' @description Finds the exact single index matching `target_name` after
#'   trimming whitespace and halts via `stop()` on zero or duplicate hits.
#' @param header_names Character vector of column headers or `Series ID` codes.
#' @param target_name Character scalar header string to locate dynamically.
#' @param source_label Character scalar source name for diagnostics.
#' @return Integer scalar index matching `target_name`.
#' @examples
#' find_col_index(c("Series ID", "FXRUSD", "FXRTWI"), "FXRUSD", "f11-data.csv")
find_col_index <- function(header_names, target_name, source_label) {
  hits <- which(trimws(header_names) == target_name)
  assert_true(
    length(hits) == 1L,
    sprintf(
      "Expected unique column '%s' in %s (found %d)",
      target_name,
      source_label,
      length(hits)
    )
  )
  hits[[1L]]
}

#' @title Normalise Date Vector to Month-Start First Day
#' @description Maps each `Date` observation onto `"YYYY-MM-01"` canonical form.
#' @param dates `Date` vector.
#' @return `Date` vector normalised to the first day of each month.
#' @examples
#' to_month_start(as.Date(c("2006-07-31", "2026-10-30")))
to_month_start <- function(dates) {
  as.Date(format(dates, "%Y-%m-01"))
}

#' @title Parse Locale-Independent `DD-Mon-YYYY` Dates
#' @description Parses RBA English abbreviated month strings without relying on
#'   OS `LC_TIME` locale settings.
#' @param x Character vector of `"DD-Mon-YYYY"` dates.
#' @return `Date` vector.
#' @examples
#' parse_dmy_mon(c("29-Jan-2010", "31-Oct-2026"))
parse_dmy_mon <- function(x) {
  month_map <- c(
    Jan = "01", Feb = "02", Mar = "03", Apr = "04",
    May = "05", Jun = "06", Jul = "07", Aug = "08",
    Sep = "09", Oct = "10", Nov = "11", Dec = "12"
  )
  parts <- strsplit(trimws(x), "-", fixed = TRUE)
  valid_len <- vapply(parts, length, integer(1L)) == 3L
  assert_true(all(valid_len), "Invalid DD-Mon-YYYY date format encountered")

  days <- sprintf("%02d", as.integer(vapply(parts, `[[`, character(1L), 1L)))
  mons <- unname(month_map[vapply(parts, `[[`, character(1L), 2L)])
  yrs <- vapply(parts, `[[`, character(1L), 3L)
  assert_true(!anyNA(mons), "Unrecognised month abbreviation in DD-Mon-YYYY")

  as.Date(paste(yrs, mons, days, sep = "-"), format = "%Y-%m-%d")
}

#' @title Parse Excel 1900-Epoch Serial Numbers Into Dates
#' @description Converts numeric or string Excel serial days (1899-12-30 epoch)
#'   into base R `Date` values.
#' @param x Numeric or character vector of Excel serial dates.
#' @return `Date` vector.
#' @examples
#' parse_excel_serial_date(c("38900", "46204"))
parse_excel_serial_date <- function(x) {
  as.Date(as.integer(round(as.numeric(x))), origin = "1899-12-30")
}

#' @title Extract World Bank Monthly Gold Spot Prices (`USD/troy oz`)
#' @description Reads `CMO-Historical-Data-Monthly.xlsx` sheet `Monthly Prices`,
#'   locates `Gold` dynamically on row 5, parses `YYYYMmm` period codes from
#'   row 7 onward, and filters to `>= 2006-01-01`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with columns `date` (`Date`) and `gold_usd`.
#' @examples
#' \dontrun{
#' extract_gold_prices("files/raw-data")
#' }
extract_gold_prices <- function(raw_dir) {
  wb_path <- file.path(raw_dir, "CMO-Historical-Data-Monthly.xlsx")
  mat <- read_xlsx_sheet(wb_path, "Monthly Prices")
  gold_col <- find_col_index(
    mat[5L, ],
    "Gold",
    "CMO-Historical-Data-Monthly.xlsx"
  )

  row_mask <- seq_len(nrow(mat)) >= 7L
  codes <- trimws(mat[row_mask, 1L])
  vals <- mat[row_mask, gold_col]
  is_period <- !is.na(codes) & grepl("^[0-9]{4}M[0-9]{2}$", codes)

  dates <- as.Date(
    sub("^([0-9]{4})M([0-9]{2})$", "\\1-\\2-01", codes[is_period]),
    format = "%Y-%m-%d"
  )
  prices <- round(as.numeric(vals[is_period]), 4L)

  out <- data.frame(date = dates, gold_usd = prices, stringsAsFactors = FALSE)
  out <- out[!is.na(out$date) & out$date >= as.Date("2006-01-01"), ]
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract Merged RBA Table F11 `AUD/USD` Exchange Rates (`FXRUSD`)
#' @description Combines `rba-exchange-rates-1969-2009.xlsx` (`2006`–`2009`)
#'   and direct `f11-data.csv` (`2010`–present) locating `FXRUSD` dynamically
#'   on row 11 and normalising dates to month-start ISO `YYYY-MM-01`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with columns `date` (`Date`) and `aud_usd`.
#' @examples
#' \dontrun{
#' extract_rba_aud_usd("files/raw-data")
#' }
extract_rba_aud_usd <- function(raw_dir) {
  hist_path <- file.path(raw_dir, "rba-exchange-rates-1969-2009.xlsx")
  mat <- read_xlsx_sheet(hist_path, "Data")
  fx_col_hist <- find_col_index(
    mat[11L, ],
    "FXRUSD",
    "rba-exchange-rates-1969-2009.xlsx"
  )
  hist_mask <- seq_len(nrow(mat)) >= 12L &
    !is.na(mat[, 1L]) &
    !is.na(mat[, fx_col_hist])
  hist_dates <- mat[hist_mask, 1L] |>
    parse_excel_serial_date() |>
    to_month_start()
  hist_df <- data.frame(
    date = hist_dates,
    aud_usd = round(as.numeric(mat[hist_mask, fx_col_hist]), 6L),
    stringsAsFactors = FALSE
  )
  hist_df <- hist_df[
    hist_df$date >= as.Date("2006-01-01") &
      hist_df$date <= as.Date("2009-12-01"),
  ]

  curr_csv <- read_rba_csv(file.path(raw_dir, "f11-data.csv"))
  fx_col_curr <- find_col_index(names(curr_csv), "FXRUSD", "f11-data.csv")
  curr_dates_raw <- trimws(curr_csv[[1L]])
  curr_vals_raw <- trimws(curr_csv[[fx_col_curr]])
  curr_keep <- nzchar(curr_dates_raw) & nzchar(curr_vals_raw)

  curr_dates <- curr_dates_raw[curr_keep] |>
    parse_dmy_mon() |>
    to_month_start()
  curr_df <- data.frame(
    date = curr_dates,
    aud_usd = round(as.numeric(curr_vals_raw[curr_keep]), 6L),
    stringsAsFactors = FALSE
  )
  curr_df <- curr_df[curr_df$date >= as.Date("2010-01-01"), ]

  out <- rbind(hist_df, curr_df)
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract `ASX:STW` Monthly Closing Prices
#' @description Reads `stw-monthly-2006-2026.xlsx`, retains only `Date` and
#'   `Price`, formats dates to `YYYY-MM-01`, and sorts ascending (`2006-07` to
#'   `2026-07`).
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with columns `date` (`Date`) and `stw_price_aud`.
#' @examples
#' \dontrun{
#' extract_stw_prices("files/raw-data")
#' }
extract_stw_prices <- function(raw_dir) {
  wb_path <- file.path(raw_dir, "stw-monthly-2006-2026.xlsx")
  mat <- read_xlsx_sheet(wb_path, "STW Historical Data.csv")
  date_col <- find_col_index(mat[1L, ], "Date", "stw-monthly-2006-2026.xlsx")
  price_col <- find_col_index(mat[1L, ], "Price", "stw-monthly-2006-2026.xlsx")

  keep <- seq_len(nrow(mat)) >= 2L &
    !is.na(mat[, date_col]) &
    !is.na(mat[, price_col])
  dates <- mat[keep, date_col] |>
    parse_excel_serial_date() |>
    to_month_start()
  prices <- round(as.numeric(mat[keep, price_col]), 4L)

  out <- data.frame(
    date = dates,
    stw_price_aud = prices,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract Normalised `ASX:STW` Cash Distributions and Franking
#' @description Parses raw `stw-dividends.csv`, converts `%` franking strings
#'   into `[0, 1]` proportions, drops `Trailing_Yield_Pct`, and sorts ascending
#'   by `ex_dividend_date`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with typed distribution columns.
#' @examples
#' \dontrun{
#' extract_stw_distributions("files/raw-data")
#' }
extract_stw_distributions <- function(raw_dir) {
  df <- utils::read.csv(
    file.path(raw_dir, "stw-dividends.csv"),
    header = TRUE,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    colClasses = "character",
    fileEncoding = "UTF-8-BOM"
  )
  keep <- nzchar(trimws(df$Ex_Dividend_Date)) & nzchar(trimws(df$Payment_Date))
  df <- df[keep, ]

  franking <- round(
    as.numeric(sub("%$", "", trimws(df$Franking_Pct))) / 100,
    6L
  )
  ex_dates <- as.Date(trimws(df$Ex_Dividend_Date), format = "%Y-%m-%d")
  pay_dates <- as.Date(trimws(df$Payment_Date), format = "%Y-%m-%d")
  out <- data.frame(
    ex_dividend_date = ex_dates,
    payment_date = pay_dates,
    cash_distribution_aud = round(
      as.numeric(trimws(df$Cash_Distribution_AUD)),
      4L
    ),
    franking_pct = franking,
    gross_distribution_aud = round(
      as.numeric(trimws(df$Gross_Distribution_AUD)),
      4L
    ),
    stringsAsFactors = FALSE
  )
  out <- out[order(out$ex_dividend_date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract Monthly RBA Table F4 Retail Deposit Rates
#' @description Reads `f4-data.csv`, locates `FRDIRSAB10K` (bonus savings) and
#'   `FRDIRBTD10K1Y` (1-year term deposit) dynamically, normalises `DD-Mon-YYYY`
#'   dates to `YYYY-MM-01`, and filters `>= 2006-01-01`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with `date`, `bonus_savings_rate_pct`, and
#'   `term_deposit_1y_rate_pct`.
#' @examples
#' \dontrun{
#' extract_rba_deposit_rates("files/raw-data")
#' }
extract_rba_deposit_rates <- function(raw_dir) {
  df <- read_rba_csv(file.path(raw_dir, "f4-data.csv"))
  col_bs <- find_col_index(names(df), "FRDIRSAB10K", "f4-data.csv")
  col_td <- find_col_index(names(df), "FRDIRBTD10K1Y", "f4-data.csv")

  raw_dt <- trimws(df[[1L]])
  raw_bs <- trimws(df[[col_bs]])
  raw_td <- trimws(df[[col_td]])
  keep <- nzchar(raw_dt) & nzchar(raw_bs) & nzchar(raw_td)

  dates <- raw_dt[keep] |>
    parse_dmy_mon() |>
    to_month_start()
  out <- data.frame(
    date = dates,
    bonus_savings_rate_pct = round(as.numeric(raw_bs[keep]), 4L),
    term_deposit_1y_rate_pct = round(as.numeric(raw_td[keep]), 4L),
    stringsAsFactors = FALSE
  )
  out <- out[out$date >= as.Date("2006-01-01"), ]
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract Quarterly ABS / RBA Table G1 Consumer Price Index (`GCPIAG`)
#' @description Reads `g1-data.csv`, locates `GCPIAG` dynamically, drops blank
#'   and empty future placeholder rows, normalises `DD/MM/YYYY` to quarter
#'   month-start, and filters `2006-06-01` through `2026-06-01`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with columns `date` (`Date`) and `cpi_index`.
#' @examples
#' \dontrun{
#' extract_abs_cpi("files/raw-data")
#' }
extract_abs_cpi <- function(raw_dir) {
  df <- read_rba_csv(file.path(raw_dir, "g1-data.csv"))
  col_cpi <- find_col_index(names(df), "GCPIAG", "g1-data.csv")

  raw_dt <- trimws(df[[1L]])
  raw_cpi <- trimws(df[[col_cpi]])
  keep <- nzchar(raw_dt) & nzchar(raw_cpi)

  dates <- as.Date(raw_dt[keep], format = "%d/%m/%Y") |>
    to_month_start()
  out <- data.frame(
    date = dates,
    cpi_index = round(as.numeric(raw_cpi[keep]), 4L),
    stringsAsFactors = FALSE
  )
  out <- out[
    out$date >= as.Date("2006-06-01") & out$date <= as.Date("2026-06-01"),
  ]
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Extract Monthly RBA Table F1.1 Cash Rate Target (`FIRMMCRT`)
#' @description Reads `f1.1-data.csv`, locates `FIRMMCRT` dynamically, removes
#'   pre-1990 blank entries and trailing lines, normalises `DD/MM/YYYY` to
#'   `YYYY-MM-01`, and filters `>= 2006-01-01`.
#' @param raw_dir Character scalar path to `files/raw-data/`.
#' @return Sorted data frame with columns `date` (`Date`) and `cash_rate_pct`.
#' @examples
#' \dontrun{
#' extract_rba_cash_rate("files/raw-data")
#' }
extract_rba_cash_rate <- function(raw_dir) {
  df <- read_rba_csv(file.path(raw_dir, "f1.1-data.csv"))
  col_crt <- find_col_index(names(df), "FIRMMCRT", "f1.1-data.csv")

  raw_dt <- trimws(df[[1L]])
  raw_crt <- trimws(df[[col_crt]])
  keep <- nzchar(raw_dt) & nzchar(raw_crt)

  dates <- as.Date(raw_dt[keep], format = "%d/%m/%Y") |>
    to_month_start()
  out <- data.frame(
    date = dates,
    cash_rate_pct = round(as.numeric(raw_crt[keep]), 4L),
    stringsAsFactors = FALSE
  )
  out <- out[out$date >= as.Date("2006-01-01"), ]
  out <- out[order(out$date), ]
  rownames(out) <- NULL
  out
}

#' @title Write Prepared UTF-8 CSV Overwriting Any Existing Extract
#' @description Formats `Date` columns explicitly as `"%Y-%m-%d"` and writes an
#'   unquoted, headered CSV using UTF-8 LF conventions.
#' @param df Data frame to serialise.
#' @param path Character scalar target CSV file path.
#' @return Invisibly returns `path`.
#' @examples
#' \dontrun{
#' write_prepared_csv(
#'   data.frame(date = as.Date("2026-07-01"), v = 1),
#'   "out.csv"
#' )
#' }
write_prepared_csv <- function(df, path) {
  formatted <- lapply(df, function(col) {
    if (inherits(col, "Date")) format(col, "%Y-%m-%d") else col
  }) |>
    as.data.frame(stringsAsFactors = FALSE)
  utils::write.table(
    formatted,
    file = path,
    sep = ",",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    eol = "\n",
    fileEncoding = "UTF-8"
  )
  invisible(path)
}

#' @title Verify Non-Null Data Frame and Strictly Ascending Unique Date Keys
#' @description Checks zero `NA` values across every column and enforces unique,
#'   strictly ascending ISO `Date` ordering on `date_col`.
#' @param df Data frame read from a prepared CSV.
#' @param date_col Character scalar date column name.
#' @param file_label Character scalar file name for error messages.
#' @return Parsed `Date` vector from `date_col`.
#' @examples
#' \dontrun{
#' assert_strict_dates(df, "date", "gold-prices.csv")
#' }
assert_strict_dates <- function(df, date_col, file_label) {
  has_na <- vapply(df, anyNA, logical(1L))
  assert_true(
    !any(has_na),
    sprintf("NA values detected in %s", file_label)
  )
  dates <- as.Date(df[[date_col]], format = "%Y-%m-%d")
  assert_true(!anyNA(dates), sprintf("Invalid dates in %s", file_label))
  assert_true(
    !anyDuplicated(dates),
    sprintf("Duplicate date keys in %s", file_label)
  )
  assert_true(
    all(diff(dates) > 0),
    sprintf("Non-ascending dates in %s", file_label)
  )
  dates
}

#' @title Assert Exact Numeric Spot Value at Key Date
#' @description Confirms a single row matches `target_date` and reconciles
#'   within numeric tolerance `1e-6`.
#' @param df Data frame read from prepared CSV.
#' @param date_col Character scalar date column name.
#' @param target_date Character scalar ISO `"YYYY-MM-DD"`.
#' @param value_col Character scalar numeric column name.
#' @param expected Numeric scalar expected value.
#' @param label Character scalar file name for error messages.
#' @return Invisibly returns `TRUE`.
#' @examples
#' \dontrun{
#' assert_spot_value(df, "date", "2006-07-01", "gold_usd", 634.0, "gold")
#' }
assert_spot_value <- function(
  df,
  date_col,
  target_date,
  value_col,
  expected,
  label
) {
  hits <- which(df[[date_col]] == target_date)
  assert_true(
    length(hits) == 1L,
    sprintf("Expected single row for %s in %s", target_date, label)
  )
  actual <- as.numeric(df[[value_col]][[hits]])
  assert_true(
    abs(actual - expected) <= 1e-6,
    sprintf(
      "Spot check failed in %s (%s %s): expected %.6f, got %.6f",
      label,
      target_date,
      value_col,
      expected,
      actual
    )
  )
  invisible(TRUE)
}

#' @title Verify All Seven Prepared CSVs Against REQ-008 Invariants
#' @description Re-reads every prepared CSV written in `files_dir` and checks
#'   row-count parity, ascending non-null date keys, franking tolerance, and
#'   exact raw-source spot values.
#' @param files_dir Character scalar path to `investment-analysis/files/`.
#' @return Named integer vector of verified row counts per prepared CSV.
#' @examples
#' \dontrun{
#' verify_prepared_csvs("files")
#' }
verify_prepared_csvs <- function(files_dir) {
  read_out <- function(name) {
    utils::read.csv(
      file.path(files_dir, name),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  gold <- read_out("gold-prices.csv")
  fx <- read_out("rba-aud-usd.csv")
  stw_p <- read_out("stw-prices.csv")
  stw_d <- read_out("stw-distributions.csv")
  dep <- read_out("rba-deposit-rates.csv")
  cpi <- read_out("abs-cpi.csv")
  cash <- read_out("rba-cash-rate.csv")

  g_dt <- assert_strict_dates(gold, "date", "gold-prices.csv")
  f_dt <- assert_strict_dates(fx, "date", "rba-aud-usd.csv")
  sp_dt <- assert_strict_dates(stw_p, "date", "stw-prices.csv")
  sd_dt <- assert_strict_dates(
    stw_d,
    "ex_dividend_date",
    "stw-distributions.csv"
  )
  dp_dt <- assert_strict_dates(dep, "date", "rba-deposit-rates.csv")
  cp_dt <- assert_strict_dates(cpi, "date", "abs-cpi.csv")
  cs_dt <- assert_strict_dates(cash, "date", "rba-cash-rate.csv")

  assert_true(
    nrow(gold) >= 250L && min(g_dt) == as.Date("2006-01-01"),
    "gold-prices.csv failed >= 250 row check"
  )
  assert_true(
    nrow(fx) >= 250L && min(f_dt) == as.Date("2006-01-01"),
    "rba-aud-usd.csv failed >= 250 row check"
  )
  assert_true(
    nrow(dep) >= 250L && min(dp_dt) == as.Date("2006-01-01"),
    "rba-deposit-rates.csv failed >= 250 row check"
  )
  assert_true(
    nrow(cash) >= 250L && min(cs_dt) == as.Date("2006-01-01"),
    "rba-cash-rate.csv failed >= 250 row check"
  )
  assert_true(
    nrow(stw_p) == 241L &&
      min(sp_dt) == as.Date("2006-07-01") &&
      max(sp_dt) == as.Date("2026-07-01"),
    "stw-prices.csv failed 241-row coverage check"
  )
  in_win <- sd_dt >= as.Date("2006-07-01") & sd_dt <= as.Date("2026-07-31")
  assert_true(
    nrow(stw_d) == 62L && sum(in_win) == 60L,
    "stw-distributions.csv failed 62 total / 60 in-window row check"
  )
  assert_true(
    nrow(cpi) == 81L &&
      min(cp_dt) == as.Date("2006-06-01") &&
      max(cp_dt) == as.Date("2026-06-01"),
    "abs-cpi.csv failed 81-row coverage check"
  )

  assert_true(
    all(stw_d$franking_pct >= 0 & stw_d$franking_pct <= 1),
    "franking_pct out of [0, 1] bounds"
  )
  expected_gross <- stw_d$cash_distribution_aud *
    (1 + stw_d$franking_pct * 30 / 70)
  assert_true(
    all(abs(stw_d$gross_distribution_aud - expected_gross) <= 0.002),
    "stw-distributions.csv franking gross-up exceeded 0.002 tolerance"
  )

  assert_spot_value(gold, "date", "2006-07-01", "gold_usd", 634.00, "gold")
  assert_spot_value(gold, "date", "2026-02-01", "gold_usd", 5020.00, "gold")
  assert_spot_value(gold, "date", "2026-07-01", "gold_usd", 4073.00, "gold")

  assert_spot_value(fx, "date", "2006-07-01", "aud_usd", 0.7658, "fx")
  assert_spot_value(fx, "date", "2026-02-01", "aud_usd", 0.7126, "fx")
  assert_spot_value(fx, "date", "2026-07-01", "aud_usd", 0.7030, "fx")

  assert_spot_value(stw_p, "date", "2006-07-01", "stw_price_aud", 49.19, "stw")
  assert_spot_value(stw_p, "date", "2026-02-01", "stw_price_aud", 82.63, "stw")
  assert_spot_value(stw_p, "date", "2026-07-01", "stw_price_aud", 80.22, "stw")

  assert_spot_value(
    dep,
    "date",
    "2006-07-01",
    "bonus_savings_rate_pct",
    4.00,
    "dep-bs"
  )
  assert_spot_value(
    dep,
    "date",
    "2008-07-01",
    "bonus_savings_rate_pct",
    5.50,
    "dep-bs"
  )
  assert_spot_value(
    dep,
    "date",
    "2021-07-01",
    "bonus_savings_rate_pct",
    0.35,
    "dep-bs"
  )
  assert_spot_value(
    dep,
    "date",
    "2025-07-01",
    "bonus_savings_rate_pct",
    4.25,
    "dep-bs"
  )
  assert_spot_value(
    dep,
    "date",
    "2026-07-01",
    "bonus_savings_rate_pct",
    4.80,
    "dep-bs"
  )

  assert_spot_value(
    dep,
    "date",
    "2006-07-01",
    "term_deposit_1y_rate_pct",
    5.40,
    "dep-td"
  )
  assert_spot_value(
    dep,
    "date",
    "2008-07-01",
    "term_deposit_1y_rate_pct",
    8.25,
    "dep-td"
  )
  assert_spot_value(
    dep,
    "date",
    "2021-07-01",
    "term_deposit_1y_rate_pct",
    0.25,
    "dep-td"
  )
  assert_spot_value(
    dep,
    "date",
    "2025-07-01",
    "term_deposit_1y_rate_pct",
    3.60,
    "dep-td"
  )
  assert_spot_value(
    dep,
    "date",
    "2026-07-01",
    "term_deposit_1y_rate_pct",
    5.00,
    "dep-td"
  )

  assert_spot_value(cash, "date", "2006-07-01", "cash_rate_pct", 5.75, "cash")
  assert_spot_value(cash, "date", "2008-08-01", "cash_rate_pct", 7.25, "cash")
  assert_spot_value(cash, "date", "2011-08-01", "cash_rate_pct", 4.75, "cash")
  assert_spot_value(cash, "date", "2020-11-01", "cash_rate_pct", 0.11, "cash")
  assert_spot_value(cash, "date", "2026-07-01", "cash_rate_pct", 4.35, "cash")

  assert_spot_value(
    stw_d,
    "ex_dividend_date",
    "2026-06-29",
    "cash_distribution_aud",
    0.7963,
    "stw-div-cash"
  )
  assert_spot_value(
    stw_d,
    "ex_dividend_date",
    "2026-06-29",
    "franking_pct",
    0.3539,
    "stw-div-frank"
  )
  assert_spot_value(
    stw_d,
    "ex_dividend_date",
    "2026-06-29",
    "gross_distribution_aud",
    0.9171,
    "stw-div-gross"
  )

  assert_spot_value(cpi, "date", "2006-06-01", "cpi_index", 59.65, "abs-cpi")
  assert_spot_value(cpi, "date", "2026-06-01", "cpi_index", 102.31, "abs-cpi")

  c(
    `gold-prices.csv` = nrow(gold),
    `rba-aud-usd.csv` = nrow(fx),
    `stw-prices.csv` = nrow(stw_p),
    `stw-distributions.csv` = nrow(stw_d),
    `rba-deposit-rates.csv` = nrow(dep),
    `abs-cpi.csv` = nrow(cpi),
    `rba-cash-rate.csv` = nrow(cash)
  )
}

#' @title Resolve Article `files/` Directory Path
#' @description Supports invoking `convert_xlsx.R` from `investment-analysis/`
#'   or directly from the parent repository root.
#' @return Character scalar path to `investment-analysis/files`.
#' @examples
#' \dontrun{
#' resolve_article_files_dir()
#' }
resolve_article_files_dir <- function() {
  if (dir.exists(file.path("files", "raw-data"))) {
    return("files")
  }
  nested <- file.path("investment-analysis", "files")
  assert_true(
    dir.exists(file.path(nested, "raw-data")),
    "Cannot locate files/raw-data/ from current working directory"
  )
  nested
}

#' @title Run Stage 1 Extraction and REQ-008 Verification
#' @description Reads all eight active datasets from `files/raw-data/`, writes
#'   or overwrites seven prepared CSVs in `files/`, and executes full checks.
#' @return Invisibly returns named integer vector of verified row counts.
#' @examples
#' \dontrun{
#' main()
#' }
main <- function() {
  files_dir <- resolve_article_files_dir()
  raw_dir <- file.path(files_dir, "raw-data")

  extractors <- list(
    `gold-prices.csv` = extract_gold_prices,
    `rba-aud-usd.csv` = extract_rba_aud_usd,
    `stw-prices.csv` = extract_stw_prices,
    `stw-distributions.csv` = extract_stw_distributions,
    `rba-deposit-rates.csv` = extract_rba_deposit_rates,
    `abs-cpi.csv` = extract_abs_cpi,
    `rba-cash-rate.csv` = extract_rba_cash_rate
  )

  lapply(names(extractors), function(csv_name) {
    df <- extractors[[csv_name]](raw_dir)
    write_prepared_csv(df, file.path(files_dir, csv_name))
  })

  counts <- verify_prepared_csvs(files_dir)
  message("Stage 1 complete. REQ-008 verification passed:")
  mapply(
    function(nm, cnt) message(sprintf("  %-24s %d rows", nm, cnt)),
    names(counts),
    counts
  )
  invisible(counts)
}

if (sys.nframe() == 0L) {
  main()
}
