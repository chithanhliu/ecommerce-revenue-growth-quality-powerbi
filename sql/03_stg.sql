-- 03_stg.sql: gộp 2 sheet, ép kiểu, bỏ vùng chồng lấn (DEC-01)
-- InvoiceDate trong CSV phải có dạng ngày đứng trước, ví dụ 1/12/2009 7:45 (style 103). Nếu CSV là mm/dd/yyyy, đổi 103 thành 101.
-- InvoiceDate in the CSV must be day first, e.g. 1/12/2009 7:45 (style 103). If yours is mm/dd/yyyy, use 101.
USE OnlineRetailII_Redesign;
GO
-- stg luôn tạo lại được từ raw, nên xóa đi tạo lại cho đơn giản
DROP TABLE IF EXISTS stg.invoice_line;
CREATE TABLE stg.invoice_line (
    source_sheet NVARCHAR(10)   NOT NULL,  -- truy ngược về sheet gốc
    source_row   INT            NOT NULL,  -- truy ngược về dòng Excel
    invoice      NVARCHAR(20)   NOT NULL,
    stock_code   NVARCHAR(20)   NOT NULL,  -- giữ nguyên bản, chuẩn hóa ở C4
    description  NVARCHAR(100)  NULL,
    quantity     INT            NOT NULL,
    invoice_date DATETIME2(0)   NOT NULL,
    price        DECIMAL(10,3)  NOT NULL,
    customer_id  INT            NULL,
    country      NVARCHAR(50)   NOT NULL,
    CONSTRAINT pk_stg_invoice_line PRIMARY KEY (source_sheet, source_row)
);

INSERT INTO stg.invoice_line
SELECT N'2009_2010', source_row, Invoice, StockCode, Description,
       TRY_CONVERT(INT, Quantity),
       TRY_CONVERT(DATETIME2(0), InvoiceDate, 103),   -- 103 = dd/mm/yyyy
       TRY_CONVERT(DECIMAL(10,3), Price),
       TRY_CONVERT(INT, CustomerID),
       Country
FROM raw.sheet_2009_2010
WHERE TRY_CONVERT(DATETIME2(0), InvoiceDate, 103) < '2010-12-01'  -- DEC-01
UNION ALL
SELECT N'2010_2011', source_row, Invoice, StockCode, Description,
       TRY_CONVERT(INT, Quantity),
       TRY_CONVERT(DATETIME2(0), InvoiceDate, 103),
       TRY_CONVERT(DECIMAL(10,3), Price),
       TRY_CONVERT(INT, CustomerID),
       Country
FROM raw.sheet_2010_2011;
GO