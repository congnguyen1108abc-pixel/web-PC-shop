$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$query = @"
-- Clean up duplicate banners
DELETE FROM Banners WHERE BannerID > 5;

-- Insert with proper escaping
IF NOT EXISTS (SELECT 1 FROM Banners WHERE Title LIKE '[[]home]%')
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

IF NOT EXISTS (SELECT 1 FROM Banners WHERE Title LIKE '[[]gaminggear]%')
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
"@

Add-Type -AssemblyName "System.Data"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Output "Cleaned up duplicates and successfully seeded home/gaminggear banners."
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
