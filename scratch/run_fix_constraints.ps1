$connectionString = "Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
$query = @"
-- Drop status check constraint
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK__Orders__Status__22751F6C')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK__Orders__Status__22751F6C;
END
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Orders_Status')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK_Orders_Status;
END

-- Drop payment status check constraint
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK__Orders__PaymentS__245D67DE')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK__Orders__PaymentS__245D67DE;
END
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Orders_PaymentStatus')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK_Orders_PaymentStatus;
END

-- Recreate with correct Unicode values
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Status CHECK (Status IN (N'Chờ xác nhận', N'Đã xác nhận', N'Đang giao', N'Hoàn tất', N'Đã hủy'));
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_PaymentStatus CHECK (PaymentStatus IN (N'Chưa thanh toán', N'Đã thanh toán', N'Hoàn tiền'));
"@

Add-Type -AssemblyName "System.Data"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Output "Successfully recreated CHECK constraints with correct Unicode strings."
} catch {
    Write-Error $_.Exception.Message
} finally {
    $connection.Close()
}
