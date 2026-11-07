USE OnlineRetailII_Redesign;
GO
-- 1. Thêm cột (chỉ thêm khi chưa có, để script chạy lại được)
IF COL_LENGTH(N'core.dim_product', N'abc_class') IS NULL
    ALTER TABLE core.dim_product ADD abc_class NVARCHAR(10) NULL;
GO
-- 2. Tính ABC trên Product Sales của P2 rồi điền vào dim_product
WITH p2 AS (
    SELECT f.product_code,
           SUM(CASE WHEN f.transaction_type = N'Sale' THEN f.line_value ELSE 0 END) AS gross_sales
    FROM core.fact_invoice_line f
    JOIN core.dim_date d    ON d.date_key = f.date_key
    JOIN core.dim_product p ON p.product_code = f.product_code
    WHERE d.period_label = N'P2' AND p.is_product = 1
    GROUP BY f.product_code
    HAVING SUM(CASE WHEN f.transaction_type = N'Sale' THEN f.line_value ELSE 0 END) > 0
), cum AS (
    SELECT product_code,
           SUM(gross_sales) OVER (ORDER BY gross_sales DESC, product_code ROWS UNBOUNDED PRECEDING)
           / SUM(gross_sales) OVER () AS cum_share
    FROM p2
)
UPDATE dp
SET abc_class = CASE WHEN c.product_code IS NULL THEN N'None'
                     WHEN c.cum_share <= 0.80 THEN N'A'
                     WHEN c.cum_share <= 0.95 THEN N'B'
                     ELSE N'C' END
FROM core.dim_product dp
LEFT JOIN cum c ON c.product_code = dp.product_code;
GO
-- 3. View hiệu suất sản phẩm, P2
CREATE OR ALTER VIEW mart.vw_product_performance AS
WITH perf AS (
    SELECT f.product_code,
           SUM(CASE WHEN f.transaction_type = N'Sale'         THEN f.line_value ELSE 0 END) AS gross_sales,
           SUM(CASE WHEN f.transaction_type = N'Cancellation' THEN f.line_value ELSE 0 END) AS cancellations,
           SUM(f.line_value)                                                                AS net_revenue,
           SUM(CASE WHEN f.transaction_type = N'Sale' THEN f.quantity ELSE 0 END)           AS units_sold,
           COUNT(DISTINCT CASE WHEN f.transaction_type = N'Sale' THEN f.invoice END)        AS sales_invoices
    FROM core.fact_invoice_line f
    JOIN core.dim_date d    ON d.date_key = f.date_key
    JOIN core.dim_product p ON p.product_code = f.product_code
    WHERE d.period_label = N'P2' AND p.is_product = 1
    GROUP BY f.product_code
)
SELECT pf.product_code, dp.description, dp.abc_class,
       pf.gross_sales, pf.cancellations, pf.net_revenue, pf.units_sold, pf.sales_invoices,
       RANK() OVER (ORDER BY pf.gross_sales DESC) AS gross_rank,
       RANK() OVER (ORDER BY pf.net_revenue DESC) AS net_rank,
       CASE WHEN pf.sales_invoices >= 50
            THEN CAST(-pf.cancellations * 100.0 / NULLIF(pf.gross_sales, 0) AS DECIMAL(6,2)) END AS cancel_rate_pct
FROM perf pf
JOIN core.dim_product dp ON dp.product_code = pf.product_code;
GO