CREATE OR ALTER PROCEDURE sp_Admin_GetFlatCompletedTransactions
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        o.OrderID, 
        od.ProductID, 
        od.Quantity, 
        od.UnitPrice, 
        ISNULL(p.ImportPrice, 0) AS ImportPrice
    FROM Orders o 
    JOIN OrderDetails od ON o.OrderID = od.OrderID 
    JOIN Products p ON od.ProductID = p.ProductID 
    WHERE o.Status = N'Hoàn tất';
END;
GO
