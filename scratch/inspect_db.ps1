$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT DISTINCT Status, PaymentStatus FROM Orders"
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
foreach ($row in $dt) {
    $status = $row.Status
    $payStatus = $row.PaymentStatus
    Write-Host "Status: $status"
    $statusChars = [char[]]$status | ForEach-Object { "[U+{0:x4}]" -f [int]$_ }
    Write-Host "  CodePoints: $($statusChars -join ' ')"
    Write-Host "PaymentStatus: $payStatus"
    $payChars = [char[]]$payStatus | ForEach-Object { "[U+{0:x4}]" -f [int]$_ }
    Write-Host "  CodePoints: $($payChars -join ' ')"
}
$conn.Close()
