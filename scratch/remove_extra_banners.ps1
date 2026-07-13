$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$query = @"
-- Delete extra home and gaminggear banners
DELETE FROM Banners WHERE Title LIKE '[[]home]%' OR Title LIKE '[[]gaminggear]%';
"@

Add-Type -AssemblyName "System.Data"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $rowsAffected = $cmd.ExecuteNonQuery()
    Write-Output "Successfully removed $rowsAffected extra banners."
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
