# Glossary

## Analysis Window

The 241 monthly observations from July 2006 to July 2026 shared by every series.
Set by the `ASX:STW` price history; longer Gold and exchange-rate history is
discarded.

## Annual Rollover

The primary Fixed Interest compounding model. At each July from 2006 to 2025,
the RBA Table F4 retail bonus savings rate (`rba-bonus-savings.csv`) is locked
for 12 months; at maturity, principal plus interest is reinvested into the next
12-month term.

## Fractional DRP

The primary `ASX:STW` Total Return model. Every cash distribution is reinvested
in full at the month's price, allowing fractional units. A theoretical benchmark
that is like-for-like with compounded Fixed Interest. Not what an ASX dividend
reinvestment plan actually does.

_Avoid_: Theoretical DRP, ideal DRP

## Gold ETF Net-of-MER

A sensitivity series adjusting gross AUD spot gold downward each month by an
ongoing ETF Management Expense Ratio (`0.15%` p.a. for `ASX:PMGOLD` or `0.40%`
p.a. for `ASX:GOLD`) to model realistic ASX gold ETF ownership.

## Prepared CSV

A UTF-8 CSV in `files/` written by the local Stage 1 script
`scripts/convert_xlsx.R`. It keeps only the columns this analysis needs, in
ascending date order, and replaces the raw source file, which is archived in
`files/raw-data/`. Read exclusively by `article.Rmd` at render time.

_Avoid_: Slim CSV, processed CSV

## Price-Only

The `ASX:STW` series that tracks unit price alone and ignores distributions.
Plotted as a dashed reference line to show what excluding dividends understates.

_Avoid_: Capital return, price return

## Total Return

Value of an investment with all income reinvested. For `ASX:STW` this is Cash
DRP; for Fixed Interest it is interest compounded via Annual Rollover; for Gold
it equals price change because Gold pays no income.

## Whole-Unit DRP

A sensitivity model mirroring a real ASX dividend reinvestment plan: starts with
`20` whole units (`AUD 983.80`), holds the `AUD 16.20` remainder plus
distributions in a `0%`-interest cash ledger (counted in portfolio value), and
buys whole units whenever cash covers one unit. The gap against Fractional DRP
is quantified in the article.
