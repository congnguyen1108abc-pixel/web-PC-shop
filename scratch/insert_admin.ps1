$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$query = @"
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@pcstore.com')
BEGIN
    INSERT INTO Users (FullName, Email, PasswordHash, LoginProvider, Role, IsActive)
    VALUES (N'Administrator', 'admin@pcstore.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Local', 'Admin', 1);
END
ELSE
BEGIN
    UPDATE Users
    SET Role = 'Admin', PasswordHash = '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'
    WHERE Email = 'admin@pcstore.com';
END
"@

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $result = $command.ExecuteNonQuery()
    
    Write-Output "SUCCESS"
    $connection.Close()
} catch {
    Write-Error $_.Exception.Message
}
