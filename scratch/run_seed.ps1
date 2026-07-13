$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$query = @"
-- 1. Insert Home and Gaming Gear banners if not exists
IF NOT EXISTS (SELECT 1 FROM Banners WHERE Title LIKE '[home]%')
BEGIN
    INSERT INTO Banners (Title, ImageURL, LinkURL, DisplayOrder, IsActive, StartDate, EndDate, CreatedAt)
    VALUES (
        N'[home] Siêu Khuyến Mãi Hè 2026',
        N'https://picsum.photos/id/1/1200/400',
        N'/products',
        1,
        1,
        GETDATE(),
        DATEADD(month, 3, GETDATE()),
        GETDATE()
    );
END

IF NOT EXISTS (SELECT 1 FROM Banners WHERE Title LIKE '[gaminggear]%')
BEGIN
    INSERT INTO Banners (Title, ImageURL, LinkURL, DisplayOrder, IsActive, StartDate, EndDate, CreatedAt)
    VALUES (
        N'[gaminggear] Premium Gaming Gear Deal',
        N'https://picsum.photos/id/2/1200/400',
        N'/gaminggear',
        1,
        1,
        GETDATE(),
        DATEADD(month, 3, GETDATE()),
        GETDATE()
    );
END

-- 2. Insert a mock order for user Chí Văn (UserID = 1) if there are no orders
IF (SELECT COUNT(*) FROM Orders) = 0
BEGIN
    DECLARE @OrderID INT;
    
    INSERT INTO Orders (UserID, OrderDate, TotalAmount, DiscountAmount, FinalAmount, Status, PaymentMethod, PaymentStatus, ShippingAddress, AdminNote, UpdatedAt)
    VALUES (
        1,
        GETDATE(),
        15990000.00,
        0.00,
        15990000.00,
        N'Chờ xác nhận',
        N'COD',
        N'Chưa thanh toán',
        N'123 Đường Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh',
        N'Đơn hàng thử nghiệm của hệ thống',
        GETDATE()
    );
    
    SET @OrderID = SCOPE_IDENTITY();
    
    -- Insert OrderDetails
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
    VALUES 
        (@OrderID, 11, 1, 4850000.00), -- Intel Core i5
        (@OrderID, 12, 1, 8990000.00), -- ASUS RTX 4060
        (@OrderID, 13, 1, 2150000.00); -- Samsung SSD 1TB
END
"@

Add-Type -AssemblyName "System.Data"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Output "Successfully seeded Banners and Order details."
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
