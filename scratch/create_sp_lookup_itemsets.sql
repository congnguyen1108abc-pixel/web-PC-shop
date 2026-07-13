CREATE OR ALTER PROCEDURE sp_Admin_GetProductLookup
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductID, ProductName FROM Products;
END;
GO

CREATE OR ALTER PROCEDURE sp_Admin_GetMinedItemsets
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ItemsetID, ProductIDs, TotalUtility, SupportCount FROM HighUtilityItemsets ORDER BY TotalUtility DESC;
END;
GO
