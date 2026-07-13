Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    $query = @"
SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS TableName,
    m.definition AS TriggerDefinition
FROM sys.triggers t
INNER JOIN sys.sql_modules m ON t.object_id = m.object_id
WHERE m.definition LIKE '%Banner%' OR m.definition LIKE '%5%'
"@
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    foreach ($row in $dt.Rows) {
        Write-Output "Trigger Name: $($row.TriggerName)"
        Write-Output "Table Name: $($row.TableName)"
        Write-Output "Definition:"
        Write-Output $row.TriggerDefinition
        Write-Output "---------------------------------------------"
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
