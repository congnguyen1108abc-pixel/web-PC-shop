Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    Write-Output "--- Current Categories ---"
    $cmdCat = New-Object System.Data.SqlClient.SqlCommand("SELECT CategoryID, CategoryName FROM Categories", $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmdCat)
    $dtCat = New-Object System.Data.DataTable
    $adapter.Fill($dtCat) | Out-Null
    $dtCat | Format-Table | Out-String | Write-Output

    Write-Output "--- Products inside PC Builder categories ---"
    $query = @"
SELECT p.ProductID, p.ProductName, p.CategoryID, c.CategoryName, pi.ImageURL
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN ProductImages pi ON p.ProductID = pi.ProductID AND pi.IsDefault = 1
WHERE p.CategoryID IN (1, 2, 3, 4, 5, 6, 8, 10)
ORDER BY p.CategoryID, p.ProductID
"@
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $dt = New-Object System.Data.DataTable
    $adapter2 = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $adapter2.Fill($dt) | Out-Null
    $dt | Format-Table | Out-String | Write-Output

} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
