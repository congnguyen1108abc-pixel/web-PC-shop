-- SQL Script: Completely remove the active banners limit trigger
-- Run this in SQL Server Management Studio (SSMS) or your database client to apply the change.

USE PC_Store;
GO

IF OBJECT_ID('dbo.trg_LimitActiveBanners', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER dbo.trg_LimitActiveBanners;
    PRINT 'Successfully dropped trg_LimitActiveBanners! Active banners limit is now removed.';
END
ELSE
BEGIN
    PRINT 'trg_LimitActiveBanners does not exist or has already been dropped.';
END
GO
