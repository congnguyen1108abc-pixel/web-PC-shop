-- SQL Migration Script: Increase active banners limit to 10
-- Run this script in SQL Server Management Studio (SSMS) or your database client to apply the change.

USE PC_Store;
GO

CREATE OR ALTER TRIGGER dbo.trg_LimitActiveBanners
ON dbo.Banners
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Increase limit from 5 to 10 (or customize as needed)
    IF (SELECT COUNT(*) FROM dbo.Banners WHERE IsActive = 1) > 10
    BEGIN
        RAISERROR(N'Lỗi: Chỉ được bật tối đa 10 Banner cùng lúc!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT 'Successfully updated trg_LimitActiveBanners to allow up to 10 active banners!';
