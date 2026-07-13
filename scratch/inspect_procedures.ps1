$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT definition FROM sys.check_constraints WHERE name = 'CK__Orders__Status__0F624AF8'"
$def = $cmd.ExecuteScalar()
Write-Host "Constraint Definition: $def"
$chars = [char[]]$def | ForEach-Object { "[U+{0:x4}]" -f [int]$_ }
Write-Host "CodePoints: $($chars -join ' ')"
$conn.Close()
