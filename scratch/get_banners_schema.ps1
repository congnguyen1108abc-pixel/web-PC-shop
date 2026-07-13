$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Banners'", $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    $dt | Format-Table | Out-String | Out-File -FilePath "d:\DoAnTMDT\PC_Store\scratch\banners_columns.txt"
} catch {
    $_.Exception.Message | Out-File -FilePath "d:\DoAnTMDT\PC_Store\scratch\banners_columns.txt"
} finally {
    $connection.Close()
}
