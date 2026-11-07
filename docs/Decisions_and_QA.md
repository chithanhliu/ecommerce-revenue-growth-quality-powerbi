# Decisions and QA

[Back to README](../README.md)

## Data preparation decisions

| ID | Decision | Why |
|---|---|---|
| DEC-01 | Keep sheet 2009-2010 rows before 1 Dec 2010, plus all of sheet 2010-2011 | The two sheets overlap in December 2010. Keeping both would count that month twice |
| DEC-02 | Keep the 11,812 lines that are exact copies of another line in the same sheet, and flag them `is_within_sheet_dup = 1` | They may be real repeat scans. Their value is £54,228.42, 0.29% of Net Revenue, so keeping or dropping them does not change any conclusion |
| DEC-03 | Gross Sales = sale lines; Net Revenue = Gross + Cancellations + Bad Debt | Separates what was sold from what was kept |
| DEC-04 | Count a cancellation in the month it happened | The data has no link from a cancellation to its original invoice |
| DEC-05 | `product_code = UPPER(TRIM(StockCode))` | Same code appears with different case or spaces |
| DEC-06 | A code is a product when its first five characters are digits; other codes go to `ref.non_product_code` | Postage, fees and manual lines are not products and would distort product rankings |
| DEC-07 | Product description = most frequent description on sale lines; ties go to the most recent | One code can have several descriptions |
| DEC-08 | Label Dec 2011 `Partial` and exclude it from period comparisons | The data ends on 9 Dec 2011, with 8 trading days |

## Implementation choices

| Choice | Detail |
|---|---|
| ABC on P2 only | Uses the latest complete year. Products with no P2 sales get `None` |
| Market | `UK` / `International`, a calculated column on the fact table |
| Revenue per Trading Day | Net Revenue ÷ days with at least one sale |
| Product cancellation rate | Shown only for products with at least 50 sales invoices in P2, so a few lines cannot create an extreme rate |
| Gross basis for YoY and AOV | Labelled on the dashboard as `Gross Sales YoY %` and `AOV (P2, Gross)` |
| Waterfall sort | `Bridge Step Order` is computed from the base columns to avoid a circular dependency |

## Change requests

The scope was frozen at 17 measures + 1 rank measure. Each change below was approved before it was built.

| ID | Change | Impact |
|---|---|---|
| CR-01 | Make the Product Detail commentary change with the selected product | Added one text measure; no change to calculations |
| CR-02 | Split that text into Observation and Interpretation, so headings match the other pages | Added a second text measure; headings became static text boxes |

## QA checks

A check is marked PASS only after it was run. QA-01 to QA-09 were re-run on the final database for this release.

| ID | Check | Expected | Result |
|---|---|---|---|
| QA-01 | Raw row counts | 525,461 and 541,910 | PASS |
| QA-02 | Rows after overlap removal | 1,044,848 | PASS |
| QA-03 | Total line value | 18,909,762.12 | PASS |
| QA-04 | Gross / Cancellations / Bad Debt | 20,522,679.86 / −1,465,303.66 / −147,614.08 | PASS |
| QA-05 | Transaction types sum to the total | difference = 0 | PASS |
| QA-06 | Bad-debt rows | 6 | PASS |
| QA-07 | Monthly Gross Sales | Nov 2010 1,470,272.48; Nov 2011 1,509,496.33; Dec 2011 638,810.68 | PASS |
| QA-08 | One row per `product_code` in `dim_product` | 0 duplicates | PASS |
| QA-09 | Every fact row matches a date and a product | 0 orphans | PASS |
| QA-10 | DAX measures vs SQL `mart` views (Gross, Net, Cancellation %, YoY) | match ± 0.01 | PASS |
| QA-11 | Product Detail drill-through and Back button | page opens with the selected product; Back returns | PASS (tested with 22423 and 23166) |

## Key figures: SQL vs Power BI

Expected values come from the SQL `mart` views. Actual values are read from the final dashboard with no slicer applied (Product Detail values with the product drilled through).

| KPI | Expected (SQL) | Actual (Power BI) | Difference |
|---|---:|---:|---:|
| Gross Sales P1 | 9,867,039.37 | 9,867,039.37 | 0.00 |
| Gross Sales P2 | 10,016,829.80 | 10,016,829.80 | 0.00 |
| Gross Sales YoY % | 1.52% | 1.52% | 0.00 pp |
| Net Revenue P1 | 9,161,996.18 | 9,161,996.18 | 0.00 |
| Net Revenue P2 | 9,314,079.92 | 9,314,079.92 | 0.00 |
| Net Revenue P1 + P2 | 18,476,076.11 | 18,476,076.11 | 0.00 |
| Sales Invoices P2 | 19,140 | 19,140 | 0 |
| AOV P2 (Gross) | 523.35 | 523.35 | 0.00 |
| Cancellation Rate % P1 / P2 / total | 5.76% / 6.91% / 6.34% | 5.76% / 6.91% / 6.34% | 0.00 pp |
| A-class products | 824 | 824 | 0 |
| 22423 Gross / Net / Cancel rate | 168,477.87 / 158,859.27 / 5.71% | 168,477.87 / 158,859.27 / 5.71% | 0.00 |
| 23166 Gross / Net / Net rank | 81,448.21 / 3,968.57 / 590 | 81,448.21 / 3,968.57 / 590 | 0.00 |

After rebuilding from the CSV files, the same checks should give the same values. `stg.invoice_line` must have 1,044,848 rows and no NULL `invoice_date`.
