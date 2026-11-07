-- 04_classify.sql: gắn transaction_type cho từng dòng (DEC-03)
USE OnlineRetailII_Redesign;
GO
CREATE OR ALTER VIEW stg.vw_invoice_line_classified AS
SELECT *,
       quantity * price AS line_value,
       CASE
           WHEN invoice LIKE N'A%'         THEN N'Bad Debt'          -- 1. tiền tố trước
           WHEN invoice LIKE N'C%'         THEN N'Cancellation'
           WHEN quantity > 0 AND price > 0 THEN N'Sale'              -- 2. rồi mới đến số
           WHEN quantity > 0 AND price = 0 THEN N'Zero Price'
           WHEN quantity < 0 AND price = 0 THEN N'Stock Adjustment'
           ELSE N'Other'                                             -- 3. lưới an toàn
       END AS transaction_type
FROM stg.invoice_line;
GO


