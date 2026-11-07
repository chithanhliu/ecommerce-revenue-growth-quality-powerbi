-- 06_fact.sql: fact table, một dòng = một invoice line; gắn cờ dòng trùng (DEC-02)
USE OnlineRetailII_Redesign;
GO
DROP TABLE IF EXISTS core.fact_invoice_line;
CREATE TABLE core.fact_invoice_line (
    source_sheet        NVARCHAR(10)  NOT NULL,
    source_row          INT           NOT NULL,
    invoice             NVARCHAR(20)  NOT NULL,
    invoice_date        DATETIME2(0)  NOT NULL,
    date_key            INT           NOT NULL,   -- nối với core.dim_date
    product_code        NVARCHAR(20)  NOT NULL,   -- nối với core.dim_product (đã UPPER/TRIM)
    customer_id         INT           NULL,
    country             NVARCHAR(50)  NOT NULL,
    transaction_type    NVARCHAR(20)  NOT NULL,
    quantity            INT           NOT NULL,
    price               DECIMAL(10,3) NOT NULL,
    line_value          DECIMAL(18,3) NOT NULL,
    is_within_sheet_dup BIT           NOT NULL,   -- 1 = bản sao thứ 2 trở đi của một dòng giống hệt
    CONSTRAINT pk_fact_invoice_line PRIMARY KEY (source_sheet, source_row)
);

WITH numbered AS (
    -- Đánh số các dòng GIỐNG HỆT NHAU ở mọi cột, trong cùng một sheet.
    -- Bản đầu tiên (theo thứ tự trong Excel) là copy_no = 1, các bản sau là 2, 3...
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY source_sheet, invoice, stock_code, description, quantity,
                                           invoice_date, price, customer_id, country
                              ORDER BY source_row) AS copy_no
    FROM stg.vw_invoice_line_classified
)
INSERT INTO core.fact_invoice_line
SELECT source_sheet, source_row, invoice, invoice_date,
       YEAR(invoice_date) * 10000 + MONTH(invoice_date) * 100 + DAY(invoice_date),
       UPPER(TRIM(stock_code)),
       customer_id, country, transaction_type, quantity, price, line_value,
       CASE WHEN copy_no > 1 THEN 1 ELSE 0 END
FROM numbered;
GO