param(
    [string]$FilePath = "scratch/seed_mock_data.sql"
)
Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $sql = [System.IO.File]::ReadAllText((Resolve-Path $FilePath), [System.Text.Encoding]::UTF8)
    # Split by GO if present, or execute as a single batch
    $batches = $sql -split "(?mi)^\s*GO\s*$"
    foreach ($batch in $batches) {
        if (![string]::IsNullOrWhiteSpace($batch)) {
            $cmd = New-Object System.Data.SqlClient.SqlCommand($batch, $connection)
            $cmd.ExecuteNonQuery() | Out-Null
        }
    }
    Write-Output "Successfully executed SQL script: $FilePath"
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
