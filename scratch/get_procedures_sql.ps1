$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

function Get-ProcedureDefinition($procName) {
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT OBJECT_DEFINITION(OBJECT_ID('$procName'))", $connection)
    return $cmd.ExecuteScalar()
}

try {
    $connection.Open()
    Write-Output "=== sp_Admin_GetUsers DEFINITION ==="
    $def1 = Get-ProcedureDefinition "sp_Admin_GetUsers"
    Write-Output $def1
    
    Write-Output "`n=== sp_Product_GetAllPaged DEFINITION ==="
    $def2 = Get-ProcedureDefinition "sp_Product_GetAllPaged"
    Write-Output $def2
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
