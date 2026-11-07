-- 02_load_raw.sql: nạp nguyên bản 2 file CSV, mọi cột là text
-- Trước khi chạy: mở data/raw/online_retail_II.xlsx, Save As từng sheet thành CSV UTF-8
-- (sheet_2009_2010.csv, sheet_2010_2011.csv), rồi sửa <REPO_PATH> bên dưới thành thư mục repo trên máy bạn.
-- Before running: save each sheet of data/raw/online_retail_II.xlsx as CSV UTF-8 and replace <REPO_PATH>.
USE OnlineRetailII_Redesign;
GO
IF OBJECT_ID(N'raw.sheet_2009_2010') IS NULL
CREATE TABLE raw.sheet_2009_2010 (
    source_row  INT IDENTITY(2,1) NOT NULL PRIMARY KEY,  -- = số dòng trong Excel
    Invoice     NVARCHAR(20)  NULL,
    StockCode   NVARCHAR(20)  NULL,
    Description NVARCHAR(100) NULL,
    Quantity    NVARCHAR(20)  NULL,
    InvoiceDate NVARCHAR(30)  NULL,
    Price       NVARCHAR(30)  NULL,
    CustomerID  NVARCHAR(20)  NULL,
    Country     NVARCHAR(50)  NULL
);
IF OBJECT_ID(N'raw.sheet_2010_2011') IS NULL
CREATE TABLE raw.sheet_2010_2011 (
    source_row  INT IDENTITY(2,1) NOT NULL PRIMARY KEY,
    Invoice     NVARCHAR(20)  NULL,
    StockCode   NVARCHAR(20)  NULL,
    Description NVARCHAR(100) NULL,
    Quantity    NVARCHAR(20)  NULL,
    InvoiceDate NVARCHAR(30)  NULL,
    Price       NVARCHAR(30)  NULL,
    CustomerID  NVARCHAR(20)  NULL,
    Country     NVARCHAR(50)  NULL
);
GO
-- View chỉ có 8 cột dữ liệu, để BULK INSERT bỏ qua cột source_row tự tăng
CREATE OR ALTER VIEW raw.v_load_2009_2010 AS
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country
FROM raw.sheet_2009_2010;
GO
CREATE OR ALTER VIEW raw.v_load_2010_2011 AS
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country
FROM raw.sheet_2010_2011;
GO
-- TRUNCATE để chạy lại không bị nhân đôi dữ liệu (đồng thời reset source_row về 2)
TRUNCATE TABLE raw.sheet_2009_2010;
BULK INSERT raw.v_load_2009_2010
FROM '<REPO_PATH>\data\raw\sheet_2009_2010.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', ROWTERMINATOR = '0x0d0a', TABLOCK);

TRUNCATE TABLE raw.sheet_2010_2011;
BULK INSERT raw.v_load_2010_2011
FROM '<REPO_PATH>\data\raw\sheet_2010_2011.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', ROWTERMINATOR = '0x0d0a', TABLOCK);
GO