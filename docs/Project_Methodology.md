# Project Methodology

[Back to README](../README.md)

## 1. Framing

The project started from one question: *is revenue really growing, and does the growth hold once cancellations and adjustments are counted?* It was split into three business questions, each answered by one page:

| ID | Question | Assumed reader | Page |
|---|---|---|---|
| BQ1 | How did revenue in P2 change versus P1? Was it driven by order count or order value? Which months peak? | Commercial director | Overview & Trend |
| BQ2 | How much Gross Sales is lost to cancellations and bad debt, by month and country? | Finance manager | Revenue Quality |
| BQ3 | Which products create revenue, and which erode it? | Buying manager | Product Performance, Product Detail |

The readers are assumed roles for a portfolio scenario, not real stakeholders. The scope was frozen before building; out of scope were customer value, retention and cohorts, country deep dives, forecasting, profit and margin, and categories.

## 2. Periods

The data runs from 1 Dec 2009 to 9 Dec 2011. Calendar years would compare 13 months against 12, so the project uses two 12-month periods starting in December:

- **P1:** Dec 2009 – Nov 2010
- **P2:** Dec 2010 – Nov 2011
- **Partial:** Dec 2011 (8 trading days), kept in totals but excluded from comparisons

## 3. Workflow

```text
Raw workbook → CSV → SQL raw → stg → core star schema → mart views (answer key)
                                         ↓
                              Power BI import → DAX measures → 4 pages → commentary
```

1. **Profile and load.** Each sheet is saved as CSV UTF-8 and loaded as text, keeping the Excel row number for tracing.
2. **Clean and classify in SQL.** Types, overlap removal, transaction types, product codes, dimensions. See [SQL Pipeline](SQL_Pipeline.md).
3. **Answer each question in SQL first.** The `mart` views give the expected numbers before any visual is built.
4. **Model in Power BI.** Import `core` tables only; no Power Query transformations. Two single-direction relationships.
5. **Measures.** 18 calculation measures, each checked against the matching `mart` view. See [DAX Measures](DAX_Measures.md).
6. **Pages and commentary.** Each page has three blocks: Key Observations, Business Interpretation and Next Analytical Step. Every number in the commentary is visible on that page or checked against SQL.

## 4. Gross → Net bridge

```text
Product Sales  19,084,294.99
+ Non-product   +799,574.19
= Gross Sales  19,883,869.18
− Cancellations −1,260,178.99
− Bad Debt       −147,614.08
= Net Revenue  18,476,076.11   (P1 + P2)
```

About 7.1% of Gross Sales does not become Net Revenue.

## 5. Validation

Every check is run, not assumed. Results are in [Decisions and QA](Decisions_and_QA.md#qa-checks).
