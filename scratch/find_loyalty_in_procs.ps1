$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand("
        SELECT OBJECT_NAME(m.object_id) AS ProcedureName, m.definition
        FROM sys.sql_modules m
        INNER JOIN sys.procedures p ON m.object_id = p.object_id
        WHERE m.definition LIKE '%loyalty%' OR m.definition LIKE '%Loyalty%'
    ", $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    
    if ($dt.Rows.Count -eq 0) {
        Write-Output "No procedures contain 'loyalty' or 'Loyalty'"
    } else {
        $dt | Format-Table -Property ProcedureName | Out-String | Write-Output
        foreach ($row in $dt.Rows) {
            Write-Output "=== Definition of $($row.ProcedureName) ==="
            Write-Output $row.definition
            Write-Output "========================================="
        }
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
