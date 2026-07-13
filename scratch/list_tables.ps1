$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME", $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    $dt | Format-Table | Out-String | Write-Output
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
