-- 01_setup.sql: tạo database và các schema cho bản redesign
IF DB_ID(N'OnlineRetailII_Redesign') IS NULL
    CREATE DATABASE OnlineRetailII_Redesign;
GO
USE OnlineRetailII_Redesign;
GO
-- CREATE SCHEMA phải đứng một mình trong batch, nên ta gọi qua EXEC
IF SCHEMA_ID(N'raw')  IS NULL EXEC(N'CREATE SCHEMA raw');
IF SCHEMA_ID(N'stg')  IS NULL EXEC(N'CREATE SCHEMA stg');
IF SCHEMA_ID(N'ref')  IS NULL EXEC(N'CREATE SCHEMA ref');
IF SCHEMA_ID(N'core') IS NULL EXEC(N'CREATE SCHEMA core');
IF SCHEMA_ID(N'mart') IS NULL EXEC(N'CREATE SCHEMA mart');
IF SCHEMA_ID(N'qa')   IS NULL EXEC(N'CREATE SCHEMA qa');
GO
SELECT name FROM sys.schemas WHERE name IN (N'raw', N'stg', N'ref', N'core', N'mart', N'qa');