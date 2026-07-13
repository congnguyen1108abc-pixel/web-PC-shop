# Load SQL Client
Add-Type -AssemblyName "System.Data"
$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
    $connection.Open()
    Write-Output "SQL Connection Opened Successfully!"

    # 1. Test sp_Admin_GetUsers
    Write-Output "`n--- Testing sp_Admin_GetUsers ---"
    $cmd = New-Object System.Data.SqlClient.SqlCommand("sp_Admin_GetUsers", $connection)
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.Parameters.AddWithValue("@Role", [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@IsActive", [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@Keyword", [DBNull]::Value) | Out-Null
    
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    Write-Output "Users found: $($dt.Rows.Count)"
    if ($dt.Rows.Count -gt 0) {
        $dt | Format-Table -Property UserId, FullName, Email, Role, IsActive | Out-String | Write-Output
    }

    # 2. Test sp_Product_GetAllPaged
    Write-Output "`n--- Testing sp_Product_GetAllPaged ---"
    $cmd2 = New-Object System.Data.SqlClient.SqlCommand("sp_Product_GetAllPaged", $connection)
    $cmd2.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd2.Parameters.AddWithValue("@CategoryId", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@BrandId", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@Keyword", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@MinPrice", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@MaxPrice", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@OnlyActive", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@SortBy", [DBNull]::Value) | Out-Null
    $cmd2.Parameters.AddWithValue("@PageNumber", 1) | Out-Null
    $cmd2.Parameters.AddWithValue("@PageSize", 10) | Out-Null
    
    $dt2 = New-Object System.Data.DataTable
    $adapter2 = New-Object System.Data.SqlClient.SqlDataAdapter($cmd2)
    $adapter2.Fill($dt2) | Out-Null
    Write-Output "Products found: $($dt2.Rows.Count)"
    if ($dt2.Rows.Count -gt 0) {
        $dt2 | Format-Table -Property ProductId, ProductName, Price, StockQuantity, IsActive | Out-String | Write-Output
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    if ($connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
    }
}
