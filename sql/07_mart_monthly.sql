USE OnlineRetailII_Redesign;
GO
CREATE OR ALTER VIEW mart.vw_monthly_revenue AS
WITH monthly AS (
    SELECT d.year_month, d.month_start, d.month_name, d.period_label, d.period_month_no,
           SUM(CASE WHEN f.transaction_type = N'Sale'         THEN f.line_value ELSE 0 END) AS gross_sales,
           SUM(CASE WHEN f.transaction_type = N'Cancellation' THEN f.line_value ELSE 0 END) AS cancellations,
           SUM(CASE WHEN f.transaction_type = N'Bad Debt'     THEN f.line_value ELSE 0 END) AS bad_debt,
           COUNT(DISTINCT CASE WHEN f.transaction_type = N'Sale' THEN f.invoice END)        AS sales_invoices,
           SUM(CASE WHEN f.transaction_type = N'Sale' THEN f.quantity ELSE 0 END)           AS units_sold,
           COUNT(DISTINCT CASE WHEN f.transaction_type = N'Sale' THEN f.date_key END)       AS trading_days
    FROM core.fact_invoice_line f
    JOIN core.dim_date d ON d.date_key = f.date_key
    GROUP BY d.year_month, d.month_start, d.month_name, d.period_label, d.period_month_no
), with_lag AS (
    SELECT *,
           gross_sales + cancellations + bad_debt                       AS net_revenue,
           CAST(gross_sales / NULLIF(sales_invoices, 0) AS DECIMAL(18,2)) AS aov,
           LAG(gross_sales, 12) OVER (ORDER BY month_start)              AS gross_same_month_ly
    FROM monthly
)
SELECT year_month, month_start, month_name, period_label, period_month_no,
       gross_sales, cancellations, bad_debt, net_revenue,
       sales_invoices, units_sold, trading_days, aov,
       CASE WHEN period_label = N'P2' THEN gross_same_month_ly END AS gross_same_month_ly,
       CASE WHEN period_label = N'P2'
            THEN CAST((gross_sales - gross_same_month_ly) * 100.0 / gross_same_month_ly AS DECIMAL(9,2))
       END AS yoy_pct
FROM with_lag;
GO
