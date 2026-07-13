Add-Type -TypeDefinition @"
using System;
using System.Security.Cryptography;
using System.Text;

public class Hasher {
    public static string HashPassword(string password) {
        using (var sha256 = SHA256.Create()) {
            var bytes = Encoding.UTF8.GetBytes(password);
            var hash = sha256.ComputeHash(bytes);
            return BitConverter.ToString(hash).Replace("-", "").ToLower();
        }
    }
}
"@

$hashed = [Hasher]::HashPassword("admin123")
Write-Output "Hashed: $hashed"
