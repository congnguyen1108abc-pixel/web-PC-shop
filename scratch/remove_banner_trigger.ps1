Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $query = "IF OBJECT_ID('dbo.trg_LimitActiveBanners', 'TR') IS NOT NULL DROP TRIGGER dbo.trg_LimitActiveBanners"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $cmd.ExecuteNonQuery()
    Write-Output "Successfully dropped trg_LimitActiveBanners trigger from database (if it existed)!"
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
