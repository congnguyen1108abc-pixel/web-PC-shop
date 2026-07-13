$body = @{
    email = "admin@pcstore.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5187/api/auth/login" -Method Post -Body $body -ContentType "application/json"
    Write-Output "Response:"
    $response | ConvertTo-Json
} catch {
    Write-Error $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Output "Error Response: $responseBody"
    }
}
