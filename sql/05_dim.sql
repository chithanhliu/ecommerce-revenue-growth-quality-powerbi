-- 05_dims.sql: bảng tra cứu mã không phải sản phẩm, dim_product, dim_date
USE OnlineRetailII_Redesign;
GO
SET DATEFIRST 1;  -- tuần bắt đầu từ thứ Hai (1 = Monday)
GO
------------------------------------------------------------
-- 1. ref.non_product_code (DEC-06)
------------------------------------------------------------
DROP TABLE IF EXISTS ref.non_product_code;
CREATE TABLE ref.non_product_code (
    product_code NVARCHAR(20) NOT NULL PRIMARY KEY,
    code_group   NVARCHAR(20) NOT NULL
);
INSERT INTO ref.non_product_code
SELECT DISTINCT
       UPPER(TRIM(stock_code)),
       CASE
           WHEN UPPER(TRIM(stock_code)) IN (N'POST', N'DOT', N'C2')                 THEN N'Shipping'
           WHEN UPPER(TRIM(stock_code)) IN (N'M', N'ADJUST', N'ADJUST2', N'B', N'D') THEN N'Manual'
           WHEN UPPER(TRIM(stock_code)) IN (N'AMAZONFEE', N'BANK CHARGES', N'CRUK')  THEN N'Fee'
           WHEN UPPER(TRIM(stock_code)) LIKE N'GIFT%'                                THEN N'Voucher'
           ELSE N'Other'
       END
FROM stg.invoice_line
WHERE UPPER(TRIM(stock_code)) NOT LIKE N'[0-9][0-9][0-9][0-9][0-9]%';  -- không bắt đầu bằng 5 chữ số
GO
------------------------------------------------------------
-- 2. core.dim_product (DEC-05, DEC-07)
------------------------------------------------------------
DROP TABLE IF EXISTS core.dim_product;
CREATE TABLE core.dim_product (
    product_code  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    description   NVARCHAR(100) NOT NULL,
    is_product    BIT           NOT NULL,
    product_group NVARCHAR(20)  NOT NULL   -- 'Product' hoặc nhóm của mã không phải sản phẩm
);
WITH codes AS (            -- mọi mã đã chuẩn hóa, để không fact row nào bị "mồ côi"
    SELECT DISTINCT UPPER(TRIM(stock_code)) AS product_code
    FROM stg.invoice_line
), descs AS (              -- mỗi cặp (mã, tên): xuất hiện bao nhiêu lần trên dòng Sale, lần cuối khi nào
    SELECT UPPER(TRIM(stock_code)) AS product_code,
           TRIM(description)       AS description,
           SUM(CASE WHEN transaction_type = N'Sale' THEN 1 ELSE 0 END) AS sale_lines,
           MAX(invoice_date)       AS last_seen
    FROM stg.vw_invoice_line_classified
    WHERE description IS NOT NULL
    GROUP BY UPPER(TRIM(stock_code)), TRIM(description)
), ranked AS (             -- xếp hạng tên trong từng mã: nhiều dòng Sale nhất, hòa thì gần nhất
    SELECT *, ROW_NUMBER() OVER (PARTITION BY product_code
                                 ORDER BY sale_lines DESC, last_seen DESC) AS rn
    FROM descs
)
INSERT INTO core.dim_product
SELECT c.product_code,
       COALESCE(r.description, N'Unknown'),
       CASE WHEN n.product_code IS NULL THEN 1 ELSE 0 END,
       COALESCE(n.code_group, N'Product')
FROM codes c
LEFT JOIN ranked r               ON r.product_code = c.product_code AND r.rn = 1
LEFT JOIN ref.non_product_code n ON n.product_code = c.product_code;
GO
------------------------------------------------------------
-- 3. core.dim_date (DEC-08)
------------------------------------------------------------
DROP TABLE IF EXISTS core.dim_date;
CREATE TABLE core.dim_date (
    date_key        INT          NOT NULL PRIMARY KEY,  -- yyyymmdd, ví dụ 20091201
    full_date       DATE         NOT NULL,
    year_no         SMALLINT     NOT NULL,
    month_no        TINYINT      NOT NULL,
    month_name      NCHAR(3)     NOT NULL,
    year_month      NCHAR(7)     NOT NULL,   -- '2009-12'
    month_start     DATE         NOT NULL,
    weekday_no      TINYINT      NOT NULL,   -- 1 = thứ Hai
    weekday_name    NVARCHAR(10) NOT NULL,
    period_label    NVARCHAR(10) NOT NULL,   -- P1, P2, Partial
    period_month_no TINYINT      NOT NULL    -- tháng thứ mấy trong period: Dec = 1 … Nov = 12
);
INSERT INTO core.dim_date
SELECT YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
       d, YEAR(d), MONTH(d),
       LEFT(DATENAME(month, d), 3),
       CONVERT(NCHAR(7), d, 126),             -- style 126 = yyyy-mm-dd..., lấy 7 ký tự đầu
       DATEFROMPARTS(YEAR(d), MONTH(d), 1),
       DATEPART(weekday, d), DATENAME(weekday, d),
       CASE WHEN d < '2010-12-01' THEN N'P1'
            WHEN d < '2011-12-01' THEN N'P2'
            ELSE N'Partial' END,
       CASE WHEN d < '2010-12-01' THEN DATEDIFF(month, '2009-12-01', d) + 1
            WHEN d < '2011-12-01' THEN DATEDIFF(month, '2010-12-01', d) + 1
            ELSE 1 END
FROM (SELECT DATEADD(day, value, CONVERT(DATE, '2009-12-01')) AS d
      FROM GENERATE_SERIES(0, 760)) AS s;     -- 761 ngày: 01/12/2009 → 31/12/2011
GO