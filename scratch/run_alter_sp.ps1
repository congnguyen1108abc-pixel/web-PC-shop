Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $sqlContent = [System.IO.File]::ReadAllText("alter_sp.sql")
    # Execute command
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sqlContent, $connection)
    $cmd.ExecuteNonQuery()
    Write-Output "Successfully executed alter_sp.sql!"
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
