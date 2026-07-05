-- 1. Create/Alter trigger for automatic slug generation on INSERT and UPDATE
IF OBJECT_ID('dbo.trg_Products_GenerateSlug', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Products_GenerateSlug;
GO

CREATE TRIGGER dbo.trg_Products_GenerateSlug
ON dbo.Products
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only update if ProductName has changed (or on insert)
    IF UPDATE(ProductName)
    BEGIN
        UPDATE p
        SET p.Slug = dbo.fn_GenerateSlug(p.ProductName)
        FROM dbo.Products p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
    END
END;
GO

-- 2. Populate/Update slugs for all existing products
UPDATE dbo.Products
SET Slug = dbo.fn_GenerateSlug(ProductName)
WHERE Slug IS NULL OR Slug <> dbo.fn_GenerateSlug(ProductName);
GO

PRINT '✓ Stored trigger trg_Products_GenerateSlug successfully created and executed.';
