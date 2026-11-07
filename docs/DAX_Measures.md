# DAX Measures

[Back to README](../README.md)

The model has **18 calculation measures** in the `_Measures` table and **3 calculated columns** on the fact table. All formulas below were read from the final PBIX. Each measure was checked against the matching SQL `mart` view (QA-10, ± 0.01).

The model also contains two text measures that write the commentary on the Product Detail page. They do not calculate a metric and are not listed here.

## Summary

| Group | Measure | Purpose | Format |
|---|---|---|---|
| Base | [Gross Sales](#gross-sales) | Value of normal sale lines (products and non-product charges). | `#,0.00` |
| Base | [Product Sales](#product-sales) | Gross Sales for product codes only. Used for ABC and Pareto. | `#,0.00` |
| Base | [Non-product Charges](#non-product-charges) | Gross Sales for postage, manual, fees and other non-product codes. | `#,0.00` |
| Base | [Cancellations](#cancellations) | Value of cancellation lines (negative), counted in the month of cancellation. | `#,0.00` |
| Base | [Bad Debt Adj](#bad-debt-adj) | Value of bad-debt adjustment lines (negative). | `#,0.00` |
| Base | [Net Revenue](#net-revenue) | Revenue kept after cancellations and bad debt. | `#,0.00` |
| Base | [Sales Invoices](#sales-invoices) | Number of distinct invoices with at least one sale line. | `#,0` |
| Base | [Units Sold](#units-sold) | Quantity on sale lines. | `#,0` |
| Ratio | [AOV](#aov) | Average order value, based on Gross Sales. Shown as AOV (P2, Gross). | `#,0.00` |
| Ratio | [Cancellation Rate %](#cancellation-rate-) | Cancelled value as a share of Gross Sales (by value, not by invoice count). | `0.00%;-0.00%;0.00%` |
| Ratio | [Revenue per Trading Day](#revenue-per-trading-day) | Net Revenue per day with at least one sale. Kept for the model; not shown on a page. | `#,0.00` |
| Period comparison | [Gross Sales P1](#gross-sales-p1) | Gross Sales for P1 (Dec 2009 to Nov 2010). | `#,0.00` |
| Period comparison | [Gross Sales P2](#gross-sales-p2) | Gross Sales for P2 (Dec 2010 to Nov 2011). | `#,0.00` |
| Period comparison | [YoY %](#yoy-) | Change in Gross Sales from P1 to P2. Shown as Gross Sales YoY %. | `0.00%;-0.00%;0.00%` |
| Product | [Product Share %](#product-share-) | A product's share of all Product Sales in the current filter. | `0.00%;-0.00%;0.00%` |
| Product | [Cumulative Share %](#cumulative-share-) | Running share of Product Sales, from the largest product down. Drives the Pareto line. | `0.00%;-0.00%;0.00%` |
| Product | [Product Cancellation Rate %](#product-cancellation-rate-) | Cancellation Rate % for one product, shown only when it has at least 50 sales invoices. | `0.00%;-0.00%;0.00%` |
| Product | [Net Revenue Rank](#net-revenue-rank) | Rank of a product by Net Revenue among all products, ties skipped. | `#,0` |

**Model:** `core fact_invoice_line` → `core dim_date` (date_key) and `core dim_product` (product_code). Many-to-one, single direction. P1 and P2 come from `dim_date[period_label]`.

## Base

### Gross Sales

Value of normal sale lines (products and non-product charges).

```dax
Gross Sales =
CALCULATE ( SUM ( 'core fact_invoice_line'[line_value] ), 'core fact_invoice_line'[transaction_type] = "Sale" )
```

### Product Sales

Gross Sales for product codes only. Used for ABC and Pareto.

```dax
Product Sales =
CALCULATE ( [Gross Sales], 'core dim_product'[is_product] = TRUE () )
```

### Non-product Charges

Gross Sales for postage, manual, fees and other non-product codes.

```dax
Non-product Charges =
CALCULATE ( [Gross Sales], 'core dim_product'[is_product] = FALSE () )
```

### Cancellations

Value of cancellation lines (negative), counted in the month of cancellation.

```dax
Cancellations =
CALCULATE ( SUM ( 'core fact_invoice_line'[line_value] ), 'core fact_invoice_line'[transaction_type] = "Cancellation" )
```

### Bad Debt Adj

Value of bad-debt adjustment lines (negative).

```dax
Bad Debt Adj =
CALCULATE ( SUM ( 'core fact_invoice_line'[line_value] ), 'core fact_invoice_line'[transaction_type] = "Bad Debt" )
```

### Net Revenue

Revenue kept after cancellations and bad debt.

```dax
Net Revenue =
[Gross Sales] + [Cancellations] + [Bad Debt Adj]
```

### Sales Invoices

Number of distinct invoices with at least one sale line.

```dax
Sales Invoices =
CALCULATE ( DISTINCTCOUNT ( 'core fact_invoice_line'[invoice] ), 'core fact_invoice_line'[transaction_type] = "Sale")
```

### Units Sold

Quantity on sale lines.

```dax
Units Sold =
CALCULATE ( SUM ( 'core fact_invoice_line'[quantity] ), 'core fact_invoice_line'[transaction_type] = "Sale" )
```

## Ratio

### AOV

Average order value, based on Gross Sales. Shown as AOV (P2, Gross).

```dax
AOV =
DIVIDE ( [Gross Sales], [Sales Invoices] )
```

### Cancellation Rate %

Cancelled value as a share of Gross Sales. It measures money, not the number of cancelled invoices.

```dax
Cancellation Rate % =
DIVIDE ( - [Cancellations], [Gross Sales] )
```

### Revenue per Trading Day

Net Revenue per day with at least one sale. Kept for the model; not shown on a page.

```dax
Revenue per Trading Day =
DIVIDE (
    [Net Revenue],
    CALCULATE ( DISTINCTCOUNT ( 'core fact_invoice_line'[date_key] ), 'core fact_invoice_line'[transaction_type] = "Sale" )
)
```

## Period comparison

### Gross Sales P1

Gross Sales for P1 (Dec 2009 to Nov 2010).

```dax
Gross Sales P1 =
CALCULATE ( [Gross Sales], 'core dim_date'[period_label] = "P1" )
```

### Gross Sales P2

Gross Sales for P2 (Dec 2010 to Nov 2011).

```dax
Gross Sales P2 =
CALCULATE ( [Gross Sales], 'core dim_date'[period_label] = "P2" )
```

### YoY %

Change in Gross Sales from P1 to P2. Shown as Gross Sales YoY %.

```dax
YoY % =
DIVIDE ( [Gross Sales P2] - [Gross Sales P1], [Gross Sales P1] )
```

## Product

### Product Share %

A product's share of all Product Sales in the current filter.

```dax
Product Share % =
DIVIDE ( [Product Sales], CALCULATE ( [Product Sales], ALL ( 'core dim_product' ) ) )
```

### Cumulative Share %

Running share of Product Sales, from the largest product down. Drives the Pareto line.

```dax
Cumulative Share % =
VAR cur     = [Product Sales]
VAR curCode = SELECTEDVALUE ( 'core dim_product'[product_code] )
VAR tbl =
    ADDCOLUMNS ( ALL ( 'core dim_product'[product_code] ), "@s", [Product Sales] )
VAR cum =
    SUMX (
        FILTER ( tbl, [@s] > cur || ( [@s] = cur && 'core dim_product'[product_code] <= curCode ) ),
        [@s]
    )
RETURN
    IF ( cur > 0, DIVIDE ( cum, SUMX ( tbl, [@s] ) ) )
```

### Product Cancellation Rate %

Cancellation Rate % for one product, shown only when it has at least 50 sales invoices.

```dax
Product Cancellation Rate % =
IF (
    HASONEVALUE ( 'core dim_product'[product_code] ) && [Sales Invoices] >= 50,
    [Cancellation Rate %]
)
```

### Net Revenue Rank

Rank of a product by Net Revenue among all products, ties skipped.

```dax
Net Revenue Rank =
IF (
    HASONEVALUE ( 'core dim_product'[product_code] ),
    RANKX (
        FILTER (
            ALL ( 'core dim_product' ),
            'core dim_product'[is_product] = TRUE () && NOT ISBLANK ( [Net Revenue] )
        ),
        [Net Revenue], , DESC, Skip
    )
)
```

## Calculated columns

These columns are on `core fact_invoice_line`. They feed the market slicer and the Gross → Net waterfall.

### Market

UK or International, used by the Market slicer.

```dax
Market =
IF ( 'core fact_invoice_line'[country] = "United Kingdom", "UK", "International" )
```

### Bridge Step

Waterfall category for each line.

```dax
Bridge Step =
SWITCH (
    TRUE (),
    'core fact_invoice_line'[transaction_type] = "Sale"
        && RELATED ( 'core dim_product'[is_product] ) = TRUE (), "Product Sales",
    'core fact_invoice_line'[transaction_type] = "Sale", "Non-product Charges",
    'core fact_invoice_line'[transaction_type] = "Cancellation", "Cancellations",
    'core fact_invoice_line'[transaction_type] = "Bad Debt", "Bad Debt",
    "Zero-value lines"
)
```

### Bridge Step Order

Sort order for Bridge Step. It is computed from the base columns, not from Bridge Step, to avoid a circular dependency.

```dax
Bridge Step Order =
SWITCH (
    TRUE (),
    'core fact_invoice_line'[transaction_type] = "Sale"
        && RELATED ( 'core dim_product'[is_product] ) = TRUE (), 1,
    'core fact_invoice_line'[transaction_type] = "Sale", 2,
    'core fact_invoice_line'[transaction_type] = "Cancellation", 3,
    'core fact_invoice_line'[transaction_type] = "Bad Debt", 4,
    5
)
```

## Notes

- **Gross basis:** YoY % and AOV are based on Gross Sales. Net Revenue grew 1.66% from P1 to P2, compared with 1.52% for Gross Sales.
- **Cancellation timing:** a cancellation is counted in the month it happened. It is not linked back to the original invoice.
- **Ranks:** `Skip` leaves gaps after ties. Gross rank on the Top 20 table is the row order, sorted by Gross Sales.
- **ABC class** is computed in SQL on P2 Product Sales and stored on `dim_product`. It is not a DAX measure.
