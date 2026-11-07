# SQL Pipeline

[Back to README](../README.md)

All cleaning, classification and modelling is done in SQL Server. Power BI only imports the `core` tables and adds measures. The scripts are in [`sql/`](../sql/) and run in number order. Comments inside the scripts are in Vietnamese.

**Requirement:** SQL Server 2022 or later. `05_dim.sql` uses `GENERATE_SERIES`, which earlier versions do not have. The project was built on SQL Server 2022 Express (`localhost\SQLEXPRESS`).

## Layers

```text
online_retail_II.xlsx ──Save As CSV UTF-8──► raw ──► stg ──► core ──► Power BI
                                                      │        │
                                                      ref      mart (answer key for DAX)
```

| Schema | Objects | Purpose |
|---|---|---|
| `raw` | `sheet_2009_2010`, `sheet_2010_2011` | The two sheets loaded as text, with `source_row` = Excel row number |
| `stg` | `invoice_line`, `vw_invoice_line_classified` | Typed and combined lines, overlap removed, transaction type added |
| `ref` | `non_product_code` | Codes that are not products (postage, fees, manual lines, vouchers) |
| `core` | `fact_invoice_line`, `dim_product`, `dim_date` | Star schema imported by Power BI |
| `mart` | `vw_monthly_revenue`, `vw_revenue_bridge`, `vw_product_performance` | One view per business question; used to check every DAX measure |

## Scripts

| Script | What it does | Decisions |
|---|---|---|
| `01_setup.sql` | Creates the `OnlineRetailII_Redesign` database and the six schemas | |
| `02_load_raw.sql` | Loads both CSV files with `BULK INSERT`; every column stays text. Replace `<REPO_PATH>` before running | |
| `03_stg.sql` | Converts types (`TRY_CONVERT`, dates as `dd/mm/yyyy`), combines the sheets and drops 2009-2010 rows from 1 Dec 2010 onward | DEC-01 |
| `04_classify.sql` | Adds `line_value = quantity × price` and `transaction_type` | DEC-03 |
| `05_dim.sql` | Builds `ref.non_product_code`, `core.dim_product` and `core.dim_date` | DEC-05 to DEC-08 |
| `06_fact.sql` | Builds `core.fact_invoice_line` and flags exact duplicates within a sheet | DEC-02 |
| `07_mart_monthly.sql` | Monthly view: gross, cancellations, bad debt, net, invoices, AOV, same month last year | |
| `08_mart_bridge.sql` | Gross → Net bridge by month and country | |
| `09_abc_product.sql` | Adds `abc_class` to `dim_product` and creates the product performance view | |

**Date format:** `03_stg.sql` converts `InvoiceDate` with style 103 (day first, e.g. `1/12/2009 7:45`). Excel writes CSV dates in the Windows regional format, so check the CSV first; if it shows `mm/dd/yyyy`, use style 101 instead. After the load, `stg.invoice_line` should have 1,044,848 rows and no NULL `invoice_date`.

`05_dim.sql` drops and recreates `dim_product`, so run `09_abc_product.sql` again whenever `05` is rerun.

## Transaction types

The order of the rules matters: invoice prefixes are checked before quantity and price.

| Rule | Type | Rows | Value (£) |
|---|---|---:|---:|
| Invoice starts with `A` | Bad Debt | 6 | −147,614.08 |
| Invoice starts with `C` | Cancellation | 19,165 | −1,465,303.66 |
| Quantity > 0 and price > 0 | Sale | 1,019,653 | 20,522,679.86 |
| Quantity > 0 and price = 0 | Zero Price | 2,631 | 0.00 |
| Quantity < 0 and price = 0 | Stock Adjustment | 3,393 | 0.00 |
| Anything else | Other | 0 | |
| **Total** | | **1,044,848** | **18,909,762.12** |

## Product codes

- `product_code = UPPER(TRIM(StockCode))`.
- A code is a product when its first five characters are digits. All other codes go to `ref.non_product_code`, grouped as Shipping, Manual, Fee, Voucher or Other.
- `dim_product` has 5,131 codes: 5,070 products and 61 non-product codes. Every code in the fact table is in `dim_product`, so no fact row is orphaned.
- Description is the one used most often on sale lines. Ties go to the most recent.

## ABC classification

Computed in `09_abc_product.sql` on **P2 Product Sales only**:

1. Rank products by P2 Product Sales, largest first.
2. Running share = `SUM() OVER (ORDER BY … ROWS UNBOUNDED PRECEDING)` ÷ total.
3. A: running share ≤ 80%; B: ≤ 95%; C: the rest.
4. Products with no P2 sales get `None`.

| Class | Products |
|---|---:|
| A | 824 |
| B | 963 |
| C | 2,002 |
| None | 1,342 |

P2 is used because it is the most recent complete year, which is what a buying decision for the next year would rely on.
