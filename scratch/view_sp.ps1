param(
    [string]$SpName = "sp_Admin_GetBanners"
)
Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT OBJECT_DEFINITION(OBJECT_ID('$SpName'))", $connection)
    $def = $cmd.ExecuteScalar()
    Write-Output $def
} finally {
    $connection.Close()
}
