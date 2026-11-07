# Data Dictionary

[Back to README](../README.md)

Tables imported into Power BI. All money is in pounds sterling (£).

## core.fact_invoice_line

One row per invoice line. 1,044,848 rows. Key: `source_sheet` + `source_row`.

| Column | Type | Description |
|---|---|---|
| `source_sheet` | text | `2009_2010` or `2010_2011`: the sheet the line came from |
| `source_row` | int | Row number in the original Excel sheet, for tracing back |
| `invoice` | text | Invoice number. Prefix `C` = cancellation, `A` = bad-debt adjustment |
| `invoice_date` | datetime | Date and time of the invoice (or of the cancellation) |
| `date_key` | int | `yyyymmdd`, joins to `dim_date` |
| `product_code` | text | `UPPER(TRIM(StockCode))`, joins to `dim_product` |
| `customer_id` | int | Customer number; blank on some lines. Not used in this analysis |
| `country` | text | Customer country (43 countries) |
| `transaction_type` | text | Sale, Cancellation, Bad Debt, Zero Price or Stock Adjustment. See [SQL Pipeline](SQL_Pipeline.md#transaction-types) |
| `quantity` | int | Units; negative on cancellations |
| `price` | decimal | Unit price |
| `line_value` | decimal | `quantity × price` |
| `is_within_sheet_dup` | bit | 1 = second or later copy of a line that is identical in every column within the same sheet |

Calculated in Power BI: `Market`, `Bridge Step`, `Bridge Step Order`. See [DAX Measures](DAX_Measures.md#calculated-columns).

## core.dim_product

One row per product code. 5,131 rows. Key: `product_code`.

| Column | Type | Description |
|---|---|---|
| `product_code` | text | Cleaned stock code |
| `description` | text | Most frequent description on sale lines; ties go to the most recent |
| `is_product` | bit | 1 when the code starts with five digits |
| `product_group` | text | `Product`, or Shipping / Manual / Fee / Voucher / Other for non-product codes |
| `abc_class` | text | A, B or C on P2 Product Sales; `None` when the product has no P2 sales |

## core.dim_date

One row per calendar day from 1 Dec 2009 to 31 Dec 2011. 761 rows. Key: `date_key`. Marked as the date table in Power BI.

| Column | Type | Description |
|---|---|---|
| `date_key` | int | `yyyymmdd` |
| `full_date` | date | Calendar date |
| `year_no`, `month_no` | int | Calendar year and month |
| `month_name` | text | `Jan` … `Dec`; sorted by `period_month_no` so the axis runs Dec → Nov |
| `year_month` | text | `yyyy-mm` |
| `month_start` | date | First day of the month |
| `weekday_no`, `weekday_name` | int, text | 1 = Monday |
| `period_label` | text | `P1` (Dec 2009 – Nov 2010), `P2` (Dec 2010 – Nov 2011), `Partial` (Dec 2011) |
| `period_month_no` | int | Month number inside the period: Dec = 1 … Nov = 12 |

## Revenue definitions

| Term | Definition |
|---|---|
| Gross Sales | Sale lines (no `C`/`A` prefix, quantity > 0, price > 0), products and non-product charges |
| Product Sales | Gross Sales for product codes only |
| Non-product Charges | Gross Sales for non-product codes, such as postage and fees |
| Cancellations | Lines with prefix `C`, counted on the cancellation date |
| Bad Debt Adjustment | Lines with prefix `A` |
| Net Revenue | Gross Sales + Cancellations + Bad Debt Adjustment |
| Cancellation Rate % | −Cancellations ÷ Gross Sales: a share of value, not of invoices |
| P1 / P2 | Dec 2009 – Nov 2010 / Dec 2010 – Nov 2011 |
| Partial | Dec 2011: 8 trading days in the data, excluded from period comparisons |
