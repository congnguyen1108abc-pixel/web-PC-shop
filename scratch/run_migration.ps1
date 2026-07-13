$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    Write-Output "Successfully connected to SQL Server!"
    
    # Read the SQL file
    $sqlFilePath = "d:\DoAnTMDT\PC_Store\scratch\fix_users_sql.sql"
    $sqlContent = Get-Content -Path $sqlFilePath -Raw
    
    # Split by GO statement
    # Using regex to split by GO on its own line (case-insensitive)
    $sqlBlocks = [System.Text.RegularExpressions.Regex]::Split($sqlContent, "(?mi)^\s*GO\s*$")
    
    foreach ($block in $sqlBlocks) {
        $trimmedBlock = $block.Trim()
        if ([string]::IsNullOrEmpty($trimmedBlock)) {
            continue
        }
        
        Write-Output "Executing SQL block..."
        $cmd = New-Object System.Data.SqlClient.SqlCommand($trimmedBlock, $connection)
        $cmd.CommandTimeout = 30
        $cmd.ExecuteNonQuery() | Out-Null
    }
    
    Write-Output "SQL Migration completed successfully!"
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
