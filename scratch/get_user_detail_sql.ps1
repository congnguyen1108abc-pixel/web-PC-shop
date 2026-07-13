$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

function Get-ProcedureDefinition($procName) {
    $cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT OBJECT_DEFINITION(OBJECT_ID('$procName'))", $connection)
    return $cmd.ExecuteScalar()
}

try {
    $connection.Open()
    Write-Output "=== sp_Admin_GetUserDetail DEFINITION ==="
    $def1 = Get-ProcedureDefinition "sp_Admin_GetUserDetail"
    Write-Output $def1
    
    Write-Output "`n=== sp_User_GetProfile DEFINITION ==="
    $def2 = Get-ProcedureDefinition "sp_User_GetProfile"
    Write-Output $def2
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
