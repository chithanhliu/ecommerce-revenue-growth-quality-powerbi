USE OnlineRetailII_Redesign;
GO
CREATE OR ALTER VIEW mart.vw_revenue_bridge AS
SELECT d.year_month, d.month_start, d.period_label, f.country,
       CASE WHEN f.country = N'United Kingdom' THEN N'UK' ELSE N'International' END AS market,
       SUM(CASE WHEN f.transaction_type = N'Sale' AND p.is_product = 1 THEN f.line_value ELSE 0 END) AS product_sales,
       SUM(CASE WHEN f.transaction_type = N'Sale' AND p.is_product = 0 THEN f.line_value ELSE 0 END) AS non_product_charges,
       SUM(CASE WHEN f.transaction_type = N'Sale'         THEN f.line_value ELSE 0 END) AS gross_sales,
       SUM(CASE WHEN f.transaction_type = N'Cancellation' THEN f.line_value ELSE 0 END) AS cancellations,
       SUM(CASE WHEN f.transaction_type = N'Bad Debt'     THEN f.line_value ELSE 0 END) AS bad_debt,
       SUM(f.line_value) AS net_revenue
FROM core.fact_invoice_line f
JOIN core.dim_date d    ON d.date_key = f.date_key
JOIN core.dim_product p ON p.product_code = f.product_code
GROUP BY d.year_month, d.month_start, d.period_label, f.country;
GO