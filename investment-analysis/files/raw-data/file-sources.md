# Sources of Raw Data

The raw inputs in `investment-analysis/files/raw-data/` were retrieved on
`2026-11-19` and `2026-11-20` (direct RBA CSVs and World Bank Pink Sheet
monthly workbook) and verified on `2026-11-20` against live upstream endpoints
via SHA-256 checksums or row-by-row content parity.

## Active Raw Source Files

Eight active datasets (five CSVs and three `.xlsx` workbooks) plus companion
research notes (`historical interest rates 2002-2026.docx`) feed Stage 1:

1. [CMO-Historical-Data-Monthly.xlsx](CMO-Historical-Data-Monthly.xlsx)
   - **Publisher & Series:** World Bank *Commodity Markets ("Pink Sheet")*,
     sheet `Monthly Prices`, column `Gold` (`USD/troy oz`, spot average of daily
     rates from June 2025; previously UK 99.5% fine London afternoon fixing
     daily average; updated `03-Nov-2026`).
   - **Canonical URL:** [World Bank CMO Monthly XLSX][wb-cmo-xlsx] (via
     [World Bank Commodity Markets][wb-cmo]).
   - **Verification:** Retrieved `2026-11-20`; `587,760` bytes, `802` monthly
     rows (`1960M01`–`2026M10`, `250` gap-free numeric rows `>= 2006-01`;
     `2006-07` = `634.00`, `2026-02` = `5020.00`, `2026-07` = `4073.00`).
     SHA-256:
     `3c8d9d8dbb48342fdbf24777c39a8ce8964cc2fd0958f72f6779e6e4ad99cde2`.

2. [f1.1-data.csv](f1.1-data.csv)
   - **Publisher & Series:** Reserve Bank of Australia (RBA) Statistical
     Table F1.1 (*Interest Rates and Yields – Money Market – Monthly*), Series
     ID `FIRMMCRT` (Cash Rate Target monthly average, published `02-Nov-2026`).
   - **Canonical URL:**
     <https://www.rba.gov.au/statistics/tables/csv/f1.1-data.csv>
     (via [RBA Statistical Tables][rba-tables]).
   - **Verification:** Retrieved `2026-11-20`; UTF-8 with BOM, `43,917` bytes,
     `DD/MM/YYYY` dates (`435` non-null `FIRMMCRT` rows `1990-08` to `2026-10`;
     `250` gap-free rows `>= 2006-01`). SHA-256:
     `52de6eef28ba1008bdde43546944b270ef08dca4c9b6282bb34846820a490ce2`.

3. [f4-data.csv](f4-data.csv)
   - **Publisher & Series:** Reserve Bank of Australia (RBA) Statistical
     Table F4 (*Retail Deposit and Investment Rates*), Series IDs
     `FRDIRSAB10K` (Banks' bonus savings accounts, AUD 10,000) and
     `FRDIRBTD10K1Y` (Banks' 1-year term deposits, AUD 10,000; published
     `06-Nov-2026`).
   - **Canonical URL:**
     <https://www.rba.gov.au/statistics/tables/csv/f4-data.csv>
     (via [RBA Statistical Tables][rba-tables]).
   - **Verification:** Retrieved `2026-11-20`; UTF-8 with BOM, `51,094` bytes,
     `DD-Mon-YYYY` dates (`293` bonus-savings rows `2002-06`–`2026-10`; `539`
     1-year TD rows `1981-12`–`2026-10`; `250` gap-free rows `>= 2006-01`).
     SHA-256:
     `d0d3f76d9dc7466b498de770cb74471e473b17ef3becf3f4fd8d0050286c95df`.

4. [f11-data.csv](f11-data.csv)
   - **Publisher & Series:** Reserve Bank of Australia (RBA) Statistical
     Table F11 (*Exchange Rates*, `2010-01` to present), Series ID `FXRUSD`
     (`A$1=USD`, published `30-Oct-2026`). Paired with item 7 for `2006`–`2009`.
   - **Canonical URL:**
     <https://www.rba.gov.au/statistics/tables/csv/f11-data.csv>
     (via [RBA Historical Data][rba-hist]).
   - **Verification:** Retrieved `2026-11-20`; UTF-8 with BOM, `34,242` bytes,
     `DD-Mon-YYYY` month-end dates (`202` rows `2010-01-29` to `2026-10-30`).
     SHA-256:
     `b27fce75b5197ada059a9ece17f128b70582b2a040340ae14ee5d5b428fe1cef`.

5. [g1-data.csv](g1-data.csv)
   - **Publisher & Series:** RBA / Australian Bureau of Statistics (ABS)
     Statistical Table G1 (*Consumer Price Inflation*), Series ID `GCPIAG`
     (`Index, September 2025 month = 100`, published `29-Oct-2026`).
   - **Canonical URL:**
     <https://www.rba.gov.au/statistics/tables/csv/g1-data.csv>
     (via [RBA Statistical Tables][rba-tables]).
   - **Verification:** Retrieved `2026-11-19`; exact SHA-256 match (`39,998`
     bytes) against live RBA download on `2026-11-20`, checksum
     `777ce0f23e8c2d176a39f033b157df5c24553cc6c63498e1adbb78c59bbf6d96`.

6. [historical interest rates 2002-2026.docx][notes-docx]
   - **Publisher & Series:** Supporting companion notes (exported from Google
     Docs) documenting ACCC *Retail Deposits Inquiry* context (~71% of bonus
     savers miss monthly rules) and RBA Table F4 annual averages.
   - **Canonical URL:** Derived from RBA Table F4:
     <https://www.rba.gov.au/statistics/tables/csv/f4-data.csv>
   - **Verification:** Retrieved `2026-11-19` (`3,580,085` bytes, SHA-256
     `8f85918bdec3cc4c264811ed1e4d6dddb40487c9e2a6f590e1e0d24556c31c43`).
     Retained as background reference; Stage 1 reads `f4-data.csv` directly.

7. [rba-exchange-rates-1969-2009.xlsx](rba-exchange-rates-1969-2009.xlsx)
   - **Publisher & Series:** Reserve Bank of Australia (RBA) Statistical Table
     F11 Historical (*Exchange Rates, 1969–2009*), Series ID `FXRUSD`
     (`A$1=USD`, converted from `.xls` to `.xlsx` via Google Sheets).
   - **Canonical URL:**
     <https://www.rba.gov.au/statistics/tables/xls-hist/f11hist-1969-2009.xls>
     (via [RBA Historical Data][rba-hist]).
   - **Verification:** Retrieved `2026-11-19` (`139,331` bytes, SHA-256
     `318fb9fc23322509fe7d46bdb29a70a195e5a3dd0b77003a5887b2ae4b02c824`);
     exact 486 / 486 `FXRUSD` row match (`1969-07-31` to `2009-12-31`, zero
     diffs) against live RBA `f11hist-1969-2009.xls`.

8. [stw-dividends.csv](stw-dividends.csv)
   - **Publisher & Series:** Compiled `ASX:STW` historical cash distribution
     and franking schedule (`2006-06-26` to `2026-09-29`, 62 rows), compiled
     from [InvestSMART STW Dividends][investsmart-stw] and cross-checked with
     State Street Global Advisors (SSGA) Australia.
   - **Canonical URL:**
     <https://www.investsmart.com.au/shares/asx-stw/state-street-spdr-sandp-asx-200-etf/dividends>
     (official issuer: [SSGA STW Product Page][ssga-stw]).
   - **Verification:** Retrieved `2026-11-19` (`3,100` bytes, SHA-256
     `e04a33a67b01ccab4bad0019ae7729bde33ec31554bd97300e1081e28c241cd5`);
     exact 46 / 46 cash & payment-date match (`2014-06`–`2026-09`) vs SSGA.
     Caveat: headline franking differs from SSGA per-unit franking credits on
     17 rows (notably `2019-06-27`, shown as `0.00%` vs `AUD 0.1923` per unit).

9. [stw-monthly-2006-2026.xlsx](stw-monthly-2006-2026.xlsx)
   - **Publisher & Series:** Investing.com Australia — *SPDR S&P/ASX 200 Fund
     (`ASX:STW`) Historical Data* (`STW Historical Data.csv`, monthly close,
     downloaded `2026-11-19` and exported via Google Sheets to `.xlsx`).
   - **Canonical URL:**
     <https://au.investing.com/etfs/spdr-s-p-asx-200-historical-data>
   - **Verification:** Retrieved `2026-11-19` (`18,028` bytes, SHA-256
     `33c14100269dadc258ef5db8a99f49ce35bcb8d0ebaa22073ef45f1c2cafed6d`);
     all 241 / 241 monthly closes cross-checked against official
     [SSGA Daily NAV History][ssga-nav] (`0.106%` mean absolute spread).

## Alternative Primary Sources

Remaining optional upstream sources verified live on `2026-11-20` should we
later refine Australian Equities (`ASX:STW`):

- **SSGA Official `ASX:STW` NAV History:** [navhist-au-en-stw.xlsx][ssga-nav] —
  daily official NAV from `2001-08-24` to present directly from the ETF issuer.
- **SSGA Official STW Distribution Table:** Embedded distribution & franking
  credit schedule (`2014-06` onward) on the [SSGA STW Product Page][ssga-stw]
  (includes exact dollar franking credits per unit for `2019-06-27`).

[notes-docx]: historical%20interest%20rates%202002-2026.docx
[wb-cmo]:
https://www.worldbank.org/en/research/commodity-markets
[wb-cmo-xlsx]:
https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/related/CMO-Historical-Data-Monthly.xlsx
[rba-tables]:
https://www.rba.gov.au/statistics/tables/
[rba-hist]:
https://www.rba.gov.au/statistics/historical-data.html
[investsmart-stw]:
https://www.investsmart.com.au/shares/asx-stw/state-street-spdr-sandp-asx-200-etf/dividends
[ssga-stw]:
https://www.ssga.com/au/en_gb/intermediary/etfs/state-street-spdr-spasx-200-etf-stw
[ssga-nav]:
https://www.ssga.com/library-content/products/fund-data/etfs/apac/navhist-au-en-stw.xlsx
