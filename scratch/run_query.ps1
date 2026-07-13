param(
    [string]$Query = "SELECT CategoryID, CategoryName FROM Categories"
)
Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    $dt | Format-Table -AutoSize | Out-String | Write-Output
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
