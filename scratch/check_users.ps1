$conn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT UserID, FullName, Email, Role, IsActive FROM Users"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Output ($reader["UserID"].ToString() + " | " + $reader["FullName"].ToString() + " | " + $reader["Email"].ToString() + " | " + $reader["Role"].ToString() + " | " + $reader["IsActive"].ToString())
}
$conn.Close()
