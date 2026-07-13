$body = @{
    email = "admin@pcstore.com"
    password = "admin123"
} | ConvertTo-Json

try {
    Write-Output "=== Testing Authentication ==="
    $loginRes = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Body $body -ContentType "application/json"
    $token = $loginRes.token
    Write-Output "Login successful. Token: $($token.Substring(0, 20))..."
    
    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $endpoints = @(
        "/api/Admin/dashboard",
        "/api/Admin/banners",
        "/api/Admin/orders?PageSize=10",
        "/api/Admin/users?PageSize=10",
        "/api/Admin/reviews?PageSize=10"
    )

    foreach ($ep in $endpoints) {
        Write-Output "`n=== Testing Endpoint: $ep ==="
        try {
            $res = Invoke-RestMethod -Uri "http://localhost:5000$ep" -Method Get -Headers $headers
            Write-Output "Status: Success"
            Write-Output "Data Type: $($res.GetType().FullName)"
            if ($res.items) {
                Write-Output "Count: $($res.items.Count)"
            } elseif ($res -is [System.Array]) {
                Write-Output "Count: $($res.Count)"
            } else {
                Write-Output "Response: $( $res | ConvertTo-Json -Depth 2 )"
            }
        } catch {
            Write-Error $_.Exception.Message
            if ($_.Exception.Response) {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Output "Error Body: $responseBody"
            }
        }
    }

} catch {
    Write-Error $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Output "Login Error Body: $responseBody"
    }
}
