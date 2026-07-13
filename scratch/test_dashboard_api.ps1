# Define URL
$baseUrl = "http://localhost:5000"

# Step 1: Login to get token
$loginBody = @{
    email = "phongrainbowsix@gmail.com"
    password = "P123456"
} | ConvertTo-Json

Write-Host "Logging in..."
try {
    $loginRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginRes.accessToken
    Write-Host "Success! Token: $($token.Substring(0, 15))..."
    Write-Host "Refresh Token: $($loginRes.refreshToken.Substring(0, 15))..."

    # Step 2: Call Dashboard API
    Write-Host "Fetching dashboard summary..."
    $headers = @{
        Authorization = "Bearer $token"
    }
    $dashboardRes = Invoke-RestMethod -Uri "$baseUrl/api/Admin/dashboard" -Method Get -Headers $headers
    Write-Host "Dashboard Summary:"
    $dashboardRes | ConvertTo-Json | Write-Host

    # Step 3: Call Revenue Report API
    Write-Host "Fetching revenue report..."
    $reportRes = Invoke-RestMethod -Uri "$baseUrl/api/Admin/revenue-report?StartDate=2026-06-13&EndDate=2026-07-13" -Method Get -Headers $headers
    Write-Host "Revenue report item count: $($reportRes.Count)"
} catch {
    Write-Error $_
}
